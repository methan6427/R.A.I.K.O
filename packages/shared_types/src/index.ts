export enum ClientEventType {
  DeviceRegister = "device.register",
  AgentRegister = "agent.register",
  CommandSend = "command.send",
  CommandResult = "command.result",
  Heartbeat = "heartbeat",
}

export enum ServerEventType {
  Ack = "ack",
  Error = "error",
  DeviceState = "device.state",
  CommandDispatch = "command.dispatch",
  CommandResult = "command.result",
}

export enum AgentCommand {
  Shutdown = "shutdown",
  Restart = "restart",
  Sleep = "sleep",
  Lock = "lock",
  OpenApp = "open_app",
}

export interface RaikoEnvelope<TPayload> {
  type: ClientEventType | ServerEventType;
  payload: TPayload;
}

export interface DeviceRegisterPayload {
  deviceId: string;
  name: string;
  platform: string;
  kind: "mobile" | "desktop";
}

export interface AgentRegisterPayload {
  agentId: string;
  name: string;
  platform: string;
}

export interface CommandSendPayload {
  commandId: string;
  sourceDeviceId: string;
  targetAgentId: string;
  action: AgentCommand;
  args?: Record<string, unknown>;
}

export interface CommandDispatchPayload extends CommandSendPayload {
  createdAt: string;
}

export interface CommandResultPayload {
  commandId: string;
  agentId: string;
  action: AgentCommand;
  status: "success" | "failed";
  output: string;
  completedAt: string;
}

export interface HeartbeatPayload {
  clientId: string;
  status: string;
  sentAt: string;
}

export interface ErrorPayload {
  message: string;
}

export interface AckPayload {
  message: string;
}

export interface DeviceSummary {
  id: string;
  name: string;
  platform: string;
  kind?: "mobile" | "desktop";
}

export interface AgentSummary {
  id: string;
  name: string;
  platform: string;
}

export interface DeviceStatePayload {
  devices: DeviceSummary[];
  agents: AgentSummary[];
}