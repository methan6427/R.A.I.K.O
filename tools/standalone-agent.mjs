#!/usr/bin/env node
/**
 * R.A.I.K.O Standalone Windows Agent
 *
 * Setup on any Windows machine with Node.js 18+:
 *   1. Copy this file to the laptop
 *   2. Run: npm init -y && npm install ws
 *   3. Run: node standalone-agent.mjs
 *
 * Or set env vars before running:
 *   set RAIKO_BACKEND_WS_URL=ws://192.168.1.XXX:8080/ws
 *   set RAIKO_AUTH_TOKEN=raiko-dev
 *   node standalone-agent.mjs
 */

import { spawn } from 'node:child_process';
import { hostname } from 'node:os';
import WebSocket from 'ws';

// ─── Configuration ───────────────────────────────────────────────────────────

const BACKEND_WS_URL = process.env.RAIKO_BACKEND_WS_URL || 'ws://CHANGE_ME:8080/ws';
const AUTH_TOKEN      = process.env.RAIKO_AUTH_TOKEN      || 'raiko-dev';
const AGENT_ID        = process.env.RAIKO_AGENT_ID        || `agent-${hostname().toLowerCase()}`;
const AGENT_NAME      = process.env.RAIKO_AGENT_NAME      || `RAIKO Agent (${hostname()})`;
const DRY_RUN         = (process.env.RAIKO_DRY_RUN || 'false').toLowerCase() === 'true';
const HEARTBEAT_MS    = 15_000;
const RECONNECT_MS    = 5_000;

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
