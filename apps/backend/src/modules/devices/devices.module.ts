import type WebSocket from "ws";
import {
  AgentCommand,
} from "@raiko/shared-types";
import type {
  AgentRegisterPayload,
  ConnectionStatus,
  DeviceRegisterPayload,
} from "@raiko/shared-types";
import { Logger } from "../../core/logger.js";
import { DeviceRegistry } from "./device-registry.js";
import type { DevicesRepository } from "./devices.repository.js";

export class DevicesModule {
  constructor(
    private readonly repository: DevicesRepository,
    private readonly registry: DeviceRegistry,
    private readonly defaultUserId: string,
    private readonly logger: Logger,
  ) {}

  async reconcileStartupState(): Promise<void> {
    const reconciliation = await this.repository.reconcileStartupState(new Date().toISOString());

    this.logger.info("Reconciled persisted connection state on startup", reconciliation);
  }

  async registerDevice(payload: DeviceRegisterPayload, socket: WebSocket): Promise<void> {
    this.registry.registerDevice({
      id: payload.deviceId,
      name: payload.name,
      platform: payload.platform,
      kind: payload.kind,
      socket,
    });

    const now = new Date().toISOString();
    await this.repository.upsertDeviceConnection({
      id: payload.deviceId,
      userId: this.defaultUserId,
      name: payload.name,
      platform: payload.platform,
      kind: payload.kind,
      connectedAt: now,
      lastSeenAt: now,
    });

    this.logger.info("Device registered", {
      deviceId: payload.deviceId,
      platform: payload.platform,
      kind: payload.kind,
    });
  }

  async registerAgent(payload: AgentRegisterPayload, socket: WebSocket): Promise<void> {
    this.registry.registerAgent({
      id: payload.agentId,
      name: payload.name,
      platform: payload.platform,
      socket,
      ...(payload.supportedCommands ? { supportedCommands: payload.supportedCommands } : {}),
    });

    const now = new Date().toISOString();
    await this.repository.upsertAgentConnection({
      id: payload.agentId,
      name: payload.name,
      platform: payload.platform,
      supportedCommands:
        payload.supportedCommands ?? [
          AgentCommand.Shutdown,
          AgentCommand.Restart,
          AgentCommand.Sleep,
          AgentCommand.Lock,
        ],
      connectedAt: now,
      lastSeenAt: now,
    });

    this.logger.info("Agent registered", {
      agentId: payload.agentId,
      platform: payload.platform,
    });
  }

  async markHeartbeat(clientId: string, status: ConnectionStatus, sentAt: string): Promise<void> {
    this.registry.markHeartbeat(clientId, status, sentAt);
    await this.repository.markHeartbeat(clientId, status, sentAt);
  }

  async markDisconnected(disconnected: { id: string; kind: "device" | "agent" }, at: string): Promise<void> {
    if (disconnected.kind === "device") {
      await this.repository.markDeviceDisconnected(disconnected.id, at);
      return;
    }

    await this.repository.markAgentDisconnected(disconnected.id, at);
  }

  async listDevices() {
    return this.repository.listOnlineDevices();
  }

  async listAgents() {
    return this.repository.listOnlineAgents();
  }
}
