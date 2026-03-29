import assert from "node:assert/strict";
import test from "node:test";
import type WebSocket from "ws";
import { AgentCommand } from "@raiko/shared-types";
import { DeviceRegistry } from "./device-registry.js";

class MockSocket {
  readonly OPEN = 1;
  readyState = 1;
  closeCode: number | undefined;
  closeReason: string | undefined;

  send(): void {}

  close(code?: number, reason?: string): void {
    this.readyState = 3;
    this.closeCode = code;
    this.closeReason = reason;
  }
}

test("DeviceRegistry tracks registration and heartbeats", () => {
  const registry = new DeviceRegistry();
  const deviceSocket = new MockSocket();
  const agentSocket = new MockSocket();

  registry.registerDevice({
    id: "mobile-01",
    name: "Mobile",
    platform: "android",
    kind: "mobile",
    socket: deviceSocket as unknown as WebSocket,
  });
  registry.registerAgent({
    id: "agent-01",
    name: "Agent",
    platform: "windows",
    socket: agentSocket as unknown as WebSocket,
    supportedCommands: [AgentCommand.Lock],
  });

  registry.markHeartbeat("agent-01", "online", "2026-03-29T10:00:00.000Z");

  assert.equal(registry.listDevices()[0]?.id, "mobile-01");
  assert.equal(registry.listAgents()[0]?.supportedCommands[0], AgentCommand.Lock);
  assert.equal(registry.listAgents()[0]?.lastSeenAt, "2026-03-29T10:00:00.000Z");
});

test("DeviceRegistry unregisters sockets by identity", () => {
  const registry = new DeviceRegistry();
  const socket = new MockSocket();

  registry.registerAgent({
    id: "agent-02",
    name: "Agent 02",
    platform: "windows",
    socket: socket as unknown as WebSocket,
  });

  const result = registry.unregisterSocket(socket as unknown as WebSocket);

  assert.deepEqual(result, {
    id: "agent-02",
    name: "Agent 02",
    kind: "agent",
  });
  assert.equal(registry.listAgents().length, 0);
});
