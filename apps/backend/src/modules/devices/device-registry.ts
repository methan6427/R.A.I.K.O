import type WebSocket from "ws";

export interface ConnectedDevice {
  id: string;
  name: string;
  platform: string;
  kind: "mobile" | "desktop";
  socket: WebSocket;
}

export interface ConnectedAgent {
  id: string;
  name: string;
  platform: string;
  socket: WebSocket;
}

export class DeviceRegistry {
  private readonly devices = new Map<string, ConnectedDevice>();
  private readonly agents = new Map<string, ConnectedAgent>();

  registerDevice(device: ConnectedDevice): void {
    this.devices.set(device.id, device);
  }

  registerAgent(agent: ConnectedAgent): void {
    this.agents.set(agent.id, agent);
  }

  unregisterSocket(socket: WebSocket): void {
    for (const [id, device] of this.devices.entries()) {
      if (device.socket === socket) {
        this.devices.delete(id);
      }
    }

    for (const [id, agent] of this.agents.entries()) {
      if (agent.socket === socket) {
        this.agents.delete(id);
      }
    }
  }

  getAgent(agentId: string): ConnectedAgent | undefined {
    return this.agents.get(agentId);
  }

  listDevices(): Array<Omit<ConnectedDevice, "socket">> {
    return Array.from(this.devices.values()).map(({ socket: _socket, ...device }) => device);
  }

  listAgents(): Array<Omit<ConnectedAgent, "socket">> {
    return Array.from(this.agents.values()).map(({ socket: _socket, ...agent }) => agent);
  }

  listClientSockets(): WebSocket[] {
    return [
      ...Array.from(this.devices.values(), (device) => device.socket),
      ...Array.from(this.agents.values(), (agent) => agent.socket),
    ];
  }
}