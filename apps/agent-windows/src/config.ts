import { AgentCommand } from "@raiko/shared-types";

export interface AgentConfig {
  agentId: string;
  agentName: string;
  platform: string;
  backendUrl: string;
  authToken?: string;
  heartbeatIntervalMs: number;
  reconnectDelayMs: number;
  dryRun: boolean;
  supportedCommands: AgentCommand[];
}

function parseBoolean(value: string | undefined, fallback: boolean): boolean {
  if (!value) {
    return fallback;
  }

  return value === "1" || value.toLowerCase() === "true";
}

function parsePositiveInt(value: string | undefined, fallback: number): number {
  const parsed = Number(value);

  if (!Number.isInteger(parsed) || parsed <= 0) {
    return fallback;
  }

  return parsed;
}

export function loadConfig(): AgentConfig {
  const authToken = process.env.RAIKO_AUTH_TOKEN || undefined;

  return {
    agentId: process.env.RAIKO_AGENT_ID ?? "agent-win-01",
    agentName: process.env.RAIKO_AGENT_NAME ?? "RAIKO Windows Agent",
    platform: "windows",
    backendUrl: process.env.RAIKO_BACKEND_WS_URL ?? "ws://127.0.0.1:8080/ws",
    heartbeatIntervalMs: parsePositiveInt(process.env.RAIKO_AGENT_HEARTBEAT_MS, 15000),
    reconnectDelayMs: parsePositiveInt(process.env.RAIKO_AGENT_RECONNECT_MS, 5000),
    dryRun: parseBoolean(process.env.RAIKO_AGENT_DRY_RUN, false),
    supportedCommands: [
      AgentCommand.Shutdown,
      AgentCommand.Restart,
      AgentCommand.Sleep,
      AgentCommand.Lock,
      AgentCommand.OpenApp,
      AgentCommand.OpenRemoteDesktop,
      AgentCommand.WakeUp,
    ],
    ...(authToken ? { authToken } : {}),
  };
}
