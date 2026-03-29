export interface AgentConfig {
  agentId: string;
  agentName: string;
  platform: string;
  backendUrl: string;
}

export function loadConfig(): AgentConfig {
  return {
    agentId: process.env.RAIKO_AGENT_ID ?? "agent-win-01",
    agentName: process.env.RAIKO_AGENT_NAME ?? "RAIKO Windows Agent",
    platform: "windows",
    backendUrl: process.env.RAIKO_BACKEND_WS_URL ?? "ws://127.0.0.1:8080/ws",
  };
}