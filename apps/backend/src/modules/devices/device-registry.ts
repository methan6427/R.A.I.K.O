import type WebSocket from "ws";
import { AgentCommand, type AgentSummary, type ConnectionStatus, type DeviceSummary } from "@raiko/shared-types";

export interface ConnectedDevice extends DeviceSummary {
  socket: WebSocket;
}

export interface ConnectedAgent extends AgentSummary {
  socket: WebSocket;
}

export interface UnregisteredClient {
  id: string;
  name: string;
  kind: "device" | "agent";
}

export class DeviceRegistry {
  private readonly devices = new Map<string, ConnectedDevice>();
  private readonly agents = new Map<string, ConnectedAgent>();

  registerDevice(device: {
    id: string;
    name: string;
    platform: string;
    kind: "mobile" | "desktop";
    socket: WebSocket;
  }): ConnectedDevice {
    this.dropExistingSocket(device.id, "device");

    const now = new Date().toISOString();
    const connected: ConnectedDevice = {
      ...device,
      status: "online",
      connectedAt: now,
      lastSeenAt: now,
    };

    this.devices.set(device.id, connected);
    return connected;
  }

  registerAgent(agent: {
    id: string;
    name: string;
    platform: string;
    socket: WebSocket;
    supportedCommands?: AgentCommand[];
  }): ConnectedAgent {
    this.dropExistingSocket(agent.id, "agent");

    const now = new Date().toISOString();
    const connected: ConnectedAgent = {
      ...agent,
      status: "online",
      connectedAt: now,
      lastSeenAt: now,
      supportedCommands: agent.supportedCommands ?? [
        AgentCommand.Shutdown,
        AgentCommand.Restart,
        AgentCommand.Sleep,
        AgentCommand.Lock,
      ],
    };

    this.agents.set(agent.id, connected);
    return connected;
  }

  unregisterSocket(socket: WebSocket): UnregisteredClient | undefined {
    for (const [id, device] of this.devices.entries()) {
      if (device.socket === socket) {
        this.devices.delete(id);
        return {
          id: device.id,
          name: device.name,
          kind: "device",
        };
      }
    }

    for (const [id, agent] of this.agents.entries()) {
      if (agent.socket === socket) {
        this.agents.delete(id);
        return {
          id: agent.id,
          name: agent.name,
          kind: "agent",
        };
      }
    }

    return undefined;
  }

  markHeartbeat(clientId: string, status: ConnectionStatus, sentAt: string): void {
    const device = this.devices.get(clientId);
    if (device) {
      device.status = status;
      device.lastSeenAt = sentAt;
      return;
    }

    const agent = this.agents.get(clientId);
    if (agent) {
      agent.status = status;
      agent.lastSeenAt = sentAt;
    }
  }

  getAgent(agentId: string): ConnectedAgent | undefined {
    return this.agents.get(agentId);
  }

  listDevices(): DeviceSummary[] {
    return Array.from(this.devices.values()).map(({ socket: _socket, ...device }) => ({ ...device }));
  }

  listAgents(): AgentSummary[] {
    return Array.from(this.agents.values()).map(({ socket: _socket, ...agent }) => ({ ...agent }));
  }

  listDeviceSockets(): WebSocket[] {
    return Array.from(this.devices.values(), (device) => device.socket);
  }

  listAgentSockets(): WebSocket[] {
    return Array.from(this.agents.values(), (agent) => agent.socket);
  }

  listClientSockets(): WebSocket[] {
    return [...this.listDeviceSockets(), ...this.listAgentSockets()];
  }

  private dropExistingSocket(id: string, kind: "device" | "agent"): void {
    const existing = kind === "device" ? this.devices.get(id)?.socket : this.agents.get(id)?.socket;

    if (existing && existing.readyState === existing.OPEN) {
      existing.close(1000, "superseded");
    }
  }
}
