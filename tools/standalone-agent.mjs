#!/usr/bin/env node
/**
 * R.A.I.K.O Standalone Windows Agent
 *
 * Setup on any Windows machine with Node.js 18+:
 *   1. Copy this file to the laptop along with a config.json (see config.example.json)
 *   2. Run: npm init -y && npm install ws
 *   3. Run: node standalone-agent.mjs
 *
 * Configuration sources (highest precedence first):
 *   1. Environment variables (RAIKO_BACKEND_WS_URL, RAIKO_AUTH_TOKEN, etc.)
 *   2. config.json next to this script
 *   3. Built-in defaults
 */

import { spawn } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { hostname } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import WebSocket from 'ws';

// ─── Configuration ───────────────────────────────────────────────────────────

// When bundled via pkg, `import.meta.url` points inside the virtual snapshot
// rather than to the exe on disk. Use `process.execPath` so config.json can
// live next to the binary.
const SCRIPT_DIR = process.pkg
  ? dirname(process.execPath)
  : dirname(fileURLToPath(import.meta.url));

// Check AppData first (for installer), then next to exe/script
function getConfigPath() {
  const appDataDir = process.env.APPDATA;
  if (appDataDir) {
    const appDataConfig = join(appDataDir, 'R.A.I.K.O', 'config.json');
    try {
      readFileSync(appDataConfig, 'utf8');
      return appDataConfig;
    } catch (err) {
      // Fall through to exe directory
    }
  }
  return join(SCRIPT_DIR, 'config.json');
}

const CONFIG_PATH = getConfigPath();

function loadConfigFile() {
  try {
    const raw = readFileSync(CONFIG_PATH, 'utf8');
    const parsed = JSON.parse(raw);
    return typeof parsed === 'object' && parsed !== null ? parsed : {};
  } catch (err) {
    if (err.code === 'ENOENT') return {};
    console.warn(`[RAIKO] Ignoring config.json (${err.message})`);
    return {};
  }
}

const fileConfig = loadConfigFile();

function pick(envKey, fileKey, fallback) {
  const envValue = process.env[envKey];
  if (envValue !== undefined && envValue !== '') return envValue;
  const fileValue = fileConfig[fileKey];
  if (fileValue !== undefined && fileValue !== null && fileValue !== '') {
    return String(fileValue);
  }
  return fallback;
}

const BACKEND_WS_URL = pick('RAIKO_BACKEND_WS_URL', 'backendWsUrl', 'ws://CHANGE_ME:8080/ws');
const AUTH_TOKEN     = pick('RAIKO_AUTH_TOKEN', 'authToken', 'raiko-dev');
const AGENT_ID       = pick('RAIKO_AGENT_ID', 'agentId', `agent-${hostname().toLowerCase()}`);
const AGENT_NAME     = pick('RAIKO_AGENT_NAME', 'agentName', `RAIKO Agent (${hostname()})`);
const DRY_RUN        = pick('RAIKO_DRY_RUN', 'dryRun', 'false').toLowerCase() === 'true';
const HEARTBEAT_MS   = Number(pick('RAIKO_HEARTBEAT_MS', 'heartbeatMs', '15000'));
const RECONNECT_MS   = Number(pick('RAIKO_RECONNECT_MS', 'reconnectMs', '5000'));

// ─── Command Handlers ────────────────────────────────────────────────────────

const COMMANDS = {
  shutdown:  { cmd: 'shutdown.exe', args: ['/s', '/t', '0', '/f'] },
  restart:   { cmd: 'shutdown.exe', args: ['/r', '/t', '0', '/f'] },
  sleep:     { cmd: 'rundll32.exe', args: ['powrprof.dll,SetSuspendState', '0,1,0'] },
  lock:      { cmd: 'rundll32.exe', args: ['user32.dll,LockWorkStation'] },
};

function executeCommand(action, args) {
  if (action === 'open_app') {
    const appPath = args?.path;
    if (!appPath) return { status: 'failed', output: 'No app path provided' };
    if (DRY_RUN) return { status: 'success', output: `[DRY RUN] Would open: ${appPath}` };
    try {
      spawn(appPath, args?.args || [], { detached: true, stdio: 'ignore' }).unref();
      return { status: 'success', output: `Opened ${appPath}` };
    } catch (e) {
      return { status: 'failed', output: e.message };
    }
  }

  const plan = COMMANDS[action];
  if (!plan) return { status: 'failed', output: `Unknown command: ${action}` };

  if (DRY_RUN) {
    return { status: 'success', output: `[DRY RUN] ${plan.cmd} ${plan.args.join(' ')}` };
  }

  try {
    spawn(plan.cmd, plan.args, { detached: true, stdio: 'ignore' }).unref();
    return { status: 'success', output: `Executed ${action}` };
  } catch (e) {
    return { status: 'failed', output: e.message };
  }
}

// ─── WebSocket Client ────────────────────────────────────────────────────────

let ws = null;
let heartbeatInterval = null;

function send(type, payload) {
  if (ws?.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ type, payload }));
  }
}

function connect() {
  console.log(`[RAIKO] Connecting to ${BACKEND_WS_URL} ...`);

  const headers = AUTH_TOKEN ? { 'x-raiko-token': AUTH_TOKEN } : {};
  ws = new WebSocket(BACKEND_WS_URL, { headers });

  ws.on('open', () => {
    console.log('[RAIKO] Connected. Registering agent...');
    send('agent.register', {
      agentId: AGENT_ID,
      name: AGENT_NAME,
      platform: 'windows',
      supportedCommands: ['shutdown', 'restart', 'sleep', 'lock', 'open_app'],
    });

    clearInterval(heartbeatInterval);
    heartbeatInterval = setInterval(() => {
      send('heartbeat', {
        clientId: AGENT_ID,
        status: 'online',
        sentAt: new Date().toISOString(),
      });
    }, HEARTBEAT_MS);
  });

  ws.on('message', (raw) => {
    try {
      const { type, payload } = JSON.parse(raw.toString());

      switch (type) {
        case 'ack':
          console.log(`[RAIKO] ${payload.message}`);
          break;

        case 'error':
          console.error(`[RAIKO] Server error: ${payload.message}`);
          break;

        case 'command.dispatch': {
          const { commandId, action, args } = payload;
          console.log(`[RAIKO] Command received: ${action} (${commandId})`);

          const result = executeCommand(action, args);
          console.log(`[RAIKO] Result: ${result.status} - ${result.output}`);

          send('command.result', {
            commandId,
            agentId: AGENT_ID,
            action,
            status: result.status,
            output: result.output,
            completedAt: new Date().toISOString(),
          });
          break;
        }

        default:
          break;
      }
    } catch (e) {
      console.error('[RAIKO] Failed to parse message:', e.message);
    }
  });

  ws.on('close', (code, reason) => {
    console.log(`[RAIKO] Disconnected (${code}). Reconnecting in ${RECONNECT_MS / 1000}s...`);
    clearInterval(heartbeatInterval);
    setTimeout(connect, RECONNECT_MS);
  });

  ws.on('error', (err) => {
    console.error(`[RAIKO] Connection error: ${err.message}`);
  });
}

// ─── Start ───────────────────────────────────────────────────────────────────

console.log('');
console.log('  +=======================================+');
console.log('  |     R.A.I.K.O  Standalone Agent       |');
console.log('  +=======================================+');
console.log('');
console.log(`  Agent ID : ${AGENT_ID}`);
console.log(`  Name     : ${AGENT_NAME}`);
console.log(`  Backend  : ${BACKEND_WS_URL}`);
console.log(`  Dry Run  : ${DRY_RUN}`);
console.log('');

if (BACKEND_WS_URL.includes('CHANGE_ME')) {
  console.error('  ERROR: Set RAIKO_BACKEND_WS_URL to your backend IP.');
  console.error('');
  console.error('  On Windows (cmd):');
  console.error('    set RAIKO_BACKEND_WS_URL=ws://192.168.1.XXX:8080/ws');
  console.error('    node standalone-agent.mjs');
  console.error('');
  console.error('  On Windows (PowerShell):');
  console.error('    $env:RAIKO_BACKEND_WS_URL="ws://192.168.1.XXX:8080/ws"');
  console.error('    node standalone-agent.mjs');
  console.error('');
  process.exit(1);
}

connect();
