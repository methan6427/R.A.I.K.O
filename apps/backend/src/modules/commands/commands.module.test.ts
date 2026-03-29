import assert from "node:assert/strict";
import test from "node:test";
import type WebSocket from "ws";
import { AgentCommand, ServerEventType, type RaikoEnvelope } from "@raiko/shared-types";
import { Logger } from "../../core/logger.js";
import { ActivityModule } from "../activity/activity.module.js";
import type { ActivityRepository } from "../activity/activity.repository.js";
import { DeviceRegistry } from "../devices/device-registry.js";
import { CommandDispatcher } from "./command-dispatcher.js";
import { CommandsModule } from "./commands.module.js";
import type { CommandsRepository, PendingCommandRecord } from "./commands.repository.js";

class MockSocket {
  readonly OPEN = 1;
  readyState = 1;
  readonly messages: string[] = [];

  send(message: string): void {
    this.messages.push(message);
  }

  close(): void {
    this.readyState = 3;
  }
}

class InMemoryActivityRepository implements ActivityRepository {
  private readonly entries = new Array<{
    actorId: string;
    type: string;
    detail: string;
    createdAt: string;
  }>();

  async insert(entry: {
    actorId: string;
    type: string;
    detail: string;
    createdAt: string;
  }) {
    this.entries.unshift(entry);
    return entry;
  }

  async listRecent(limit: number) {
    return this.entries.slice(0, limit);
  }
}

class InMemoryCommandsRepository implements CommandsRepository {
  private readonly records = new Map<
    string,
    PendingCommandRecord & {
      status: "pending" | "success" | "failed";
      output?: string;
      completedAt?: string;
    }
  >();

  async storePending(command: PendingCommandRecord): Promise<void> {
    this.records.set(command.commandId, {
      ...command,
      status: "pending",
    });
  }

  async recordFailure(result: {
    commandId: string;
    agentId: string;
    action: AgentCommand;
    status: "success" | "failed";
    output: string;
    completedAt: string;
  }): Promise<void> {
    await this.update(result);
  }

  async recordResult(result: {
    commandId: string;
    agentId: string;
    action: AgentCommand;
    status: "success" | "failed";
    output: string;
    completedAt: string;
  }): Promise<void> {
    await this.update(result);
  }

  async listRecent(limit: number) {
    return Array.from(this.records.values())
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt))
      .slice(0, limit)
      .map((record) => ({
        commandId: record.commandId,
        sourceDeviceId: record.sourceDeviceId,
        targetAgentId: record.targetAgentId,
        action: record.action,
        status: record.status,
        createdAt: record.createdAt,
        ...(record.args ? { args: record.args } : {}),
        ...(record.output ? { output: record.output } : {}),
        ...(record.completedAt ? { completedAt: record.completedAt } : {}),
      }));
  }

  private async update(result: {
    commandId: string;
    agentId: string;
    action: AgentCommand;
    status: "success" | "failed";
    output: string;
    completedAt: string;
  }): Promise<void> {
    const current = this.records.get(result.commandId);
    if (!current) {
      return;
    }

    this.records.set(result.commandId, {
      ...current,
      status: result.status,
      output: result.output,
      completedAt: result.completedAt,
    });
  }
}

function createSilentLogger(scope: string): Logger {
  return new Logger(scope, {
    minLevel: "error",
    sink: () => {},
  });
}

test("CommandsModule queues and dispatches commands to connected agents", async () => {
  const registry = new DeviceRegistry();
  const activity = new ActivityModule(new InMemoryActivityRepository(), createSilentLogger("activity"));
  const commands = new CommandsModule(
    new InMemoryCommandsRepository(),
    new CommandDispatcher(registry, createSilentLogger("commands")),
    activity,
  );
  const socket = new MockSocket();

  registry.registerAgent({
    id: "agent-01",
    name: "Agent",
    platform: "windows",
    socket: socket as unknown as WebSocket,
  });

  const result = await commands.dispatch({
    commandId: "cmd-1",
    sourceDeviceId: "mobile-01",
    targetAgentId: "agent-01",
    action: AgentCommand.Lock,
  });

  assert.equal(result.ok, true);
  assert.equal((await commands.list())[0]?.status, "pending");

  const envelope = JSON.parse(socket.messages[0] ?? "") as RaikoEnvelope<{ action: AgentCommand }>;
  assert.equal(envelope.type, ServerEventType.CommandDispatch);
  assert.equal(envelope.payload.action, AgentCommand.Lock);
});

test("CommandsModule marks failed dispatches when the agent is offline", async () => {
  const registry = new DeviceRegistry();
  const activity = new ActivityModule(new InMemoryActivityRepository(), createSilentLogger("activity"));
  const commands = new CommandsModule(
    new InMemoryCommandsRepository(),
    new CommandDispatcher(registry, createSilentLogger("commands")),
    activity,
  );

  const result = await commands.dispatch({
    commandId: "cmd-2",
    sourceDeviceId: "mobile-01",
    targetAgentId: "missing-agent",
    action: AgentCommand.Sleep,
  });

  assert.equal(result.ok, false);
  assert.equal((await commands.list())[0]?.status, "failed");
});

test("CommandsModule records command results", async () => {
  const registry = new DeviceRegistry();
  const activity = new ActivityModule(new InMemoryActivityRepository(), createSilentLogger("activity"));
  const commands = new CommandsModule(
    new InMemoryCommandsRepository(),
    new CommandDispatcher(registry, createSilentLogger("commands")),
    activity,
  );

  await commands.dispatch({
    commandId: "cmd-3",
    sourceDeviceId: "mobile-01",
    targetAgentId: "missing-agent",
    action: AgentCommand.Restart,
  });

  await commands.recordResult({
    commandId: "cmd-3",
    agentId: "missing-agent",
    action: AgentCommand.Restart,
    status: "success",
    output: "done",
    completedAt: "2026-03-29T10:05:00.000Z",
  });

  assert.equal((await commands.list())[0]?.status, "success");
  assert.equal((await commands.list())[0]?.output, "done");
});
