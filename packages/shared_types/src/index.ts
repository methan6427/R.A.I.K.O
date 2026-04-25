export type ConnectionStatus = "online" | "offline";
export type CommandExecutionStatus = "pending" | "success" | "failed";

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
  ActivitySnapshot = "activity.snapshot",
  CommandSnapshot = "command.snapshot",
  CommandDispatch = "command.dispatch",
  CommandResult = "command.result",
}

export enum AgentCommand {
  Shutdown = "shutdown",
  Restart = "restart",
  Sleep = "sleep",
  Lock = "lock",
  OpenApp = "open_app",
  OpenRemoteDesktop = "open_remote_desktop",
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
  supportedCommands?: AgentCommand[];
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
  status: ConnectionStatus;
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
  kind: "mobile" | "desktop";
  status: ConnectionStatus;
  connectedAt: string;
  lastSeenAt: string;
}

export interface AgentSummary {
  id: string;
  name: string;
  platform: string;
  status: ConnectionStatus;
  connectedAt: string;
  lastSeenAt: string;
  supportedCommands: AgentCommand[];
}

export interface DeviceStatePayload {
  devices: DeviceSummary[];
  agents: AgentSummary[];
}

export interface ActivityEntry {
  type: string;
  actorId: string;
  detail: string;
  createdAt: string;
}

export interface ActivitySnapshotPayload {
  activity: ActivityEntry[];
}

export interface CommandLogEntry {
  commandId: string;
  sourceDeviceId: string;
  targetAgentId: string;
  action: AgentCommand;
  status: CommandExecutionStatus;
  args?: Record<string, unknown>;
  output?: string;
  createdAt: string;
  completedAt?: string;
}

export interface CommandSnapshotPayload {
  commands: CommandLogEntry[];
}
