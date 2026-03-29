import assert from "node:assert/strict";
import type { AddressInfo } from "node:net";
import test from "node:test";
import WebSocket, { type RawData } from "ws";
import {
  AgentCommand,
  ClientEventType,
  ServerEventType,
  type CommandDispatchPayload,
  type CommandLogEntry,
  type CommandResultPayload,
  type RaikoEnvelope,
} from "@raiko/shared-types";
import type { BackendConfig } from "../config/env.js";
import { Logger } from "../core/logger.js";
import { createInMemoryDatabase } from "../database/test-database.js";
import { createApp } from "./create-app.js";

test("persisted command dispatch and result flow survives app recreation", async (t) => {
  const logger = new Logger("test", {
    minLevel: "error",
    sink: () => {},
  });
  const database = createInMemoryDatabase(logger);
  const config: BackendConfig = {
    environment: "test",
    host: "127.0.0.1",
    port: 0,
    authToken: "integration-secret",
    activityLimit: 50,
    commandLimit: 50,
    logLevel: "error",
    runMigrations: true,
    database: {
      url: "postgres://raiko:test@localhost:5432/raiko_test",
      sslMode: "disable",
    },
    bootstrapUser: {
      id: "operator-admin",
      email: "admin@raiko.local",
      displayName: "R.A.I.K.O Operator",
    },
  };

  let secondApp: Awaited<ReturnType<typeof createApp>> | undefined;

  t.after(async () => {
    await secondApp?.app.close().catch(() => undefined);
    await database.close();
  });

  const firstApp = await createApp(config, {
    logger,
    database,
  });

  t.after(async () => {
    await firstApp.app.close().catch(() => undefined);
  });

  firstApp.attachGateway();
  await firstApp.app.listen({
    host: "127.0.0.1",
    port: 0,
  });

  const address = firstApp.app.server.address();
  assert.notEqual(address, null);
  assert.equal(typeof address, "object");

  const wsUrl = `ws://127.0.0.1:${(address as AddressInfo).port}/ws?token=${config.authToken!}`;
  const agentSocket = await connectWebSocket(wsUrl);
  const deviceSocket = await connectWebSocket(wsUrl);

  t.after(async () => {
    await closeWebSocket(agentSocket);
    await closeWebSocket(deviceSocket);
  });

  const agentAckPromise = waitForEnvelope(agentSocket, (envelope) => envelope.type === ServerEventType.Ack);
  sendEnvelope(agentSocket, {
    type: ClientEventType.AgentRegister,
    payload: {
      agentId: "agent-01",
      name: "Windows Agent",
      platform: "windows",
      supportedCommands: [AgentCommand.Lock],
    },
  });
  await agentAckPromise;

  const deviceAckPromise = waitForEnvelope(deviceSocket, (envelope) => envelope.type === ServerEventType.Ack);
  sendEnvelope(deviceSocket, {
    type: ClientEventType.DeviceRegister,
    payload: {
      deviceId: "mobile-01",
      name: "Operator Phone",
      platform: "android",
      kind: "mobile",
    },
  });
  await deviceAckPromise;

  const dispatchPromise = waitForEnvelope(
    agentSocket,
    (envelope) => envelope.type === ServerEventType.CommandDispatch,
  );
  const dispatchResponse = await firstApp.app.inject({
    method: "POST",
    url: "/api/commands",
    headers: {
      "content-type": "application/json",
      "x-raiko-token": config.authToken!,
    },
    payload: {
      commandId: "cmd-1",
      sourceDeviceId: "mobile-01",
      targetAgentId: "agent-01",
      action: AgentCommand.Lock,
    },
  });

  assert.equal(dispatchResponse.statusCode, 202);

  const dispatchEnvelope = await dispatchPromise;
  const dispatchPayload = dispatchEnvelope.payload as CommandDispatchPayload;
  assert.equal(dispatchPayload.commandId, "cmd-1");
  assert.equal(dispatchPayload.action, AgentCommand.Lock);

  const resultBroadcastPromise = waitForEnvelope(
    deviceSocket,
    (envelope) =>
      envelope.type === ServerEventType.CommandResult &&
      (envelope.payload as CommandResultPayload).commandId === "cmd-1",
  );
  sendEnvelope(agentSocket, {
    type: ClientEventType.CommandResult,
    payload: {
      commandId: "cmd-1",
      agentId: "agent-01",
      action: AgentCommand.Lock,
      status: "success",
      output: "locked",
      completedAt: "2026-03-29T10:10:00.000Z",
    },
  });
  await resultBroadcastPromise;

  await closeWebSocket(agentSocket);
  await closeWebSocket(deviceSocket);
  await firstApp.app.close();

  secondApp = await createApp(
    {
      ...config,
      runMigrations: false,
    },
    {
      logger,
      database,
    },
  );

  const commandsResponse = await secondApp.app.inject({
    method: "GET",
    url: "/api/commands",
    headers: {
      "x-raiko-token": config.authToken!,
    },
  });
  const commandsBody = JSON.parse(commandsResponse.body) as {
    commands: CommandLogEntry[];
  };

  assert.equal(commandsBody.commands[0]?.commandId, "cmd-1");
  assert.equal(commandsBody.commands[0]?.status, "success");
  assert.equal(commandsBody.commands[0]?.output, "locked");

  const activityResponse = await secondApp.app.inject({
    method: "GET",
    url: "/api/activity",
    headers: {
      "x-raiko-token": config.authToken!,
    },
  });
  const activityBody = JSON.parse(activityResponse.body) as {
    activity: Array<{ type: string }>;
  };

  assert.equal(activityBody.activity.some((entry) => entry.type === "command.dispatch"), true);
  assert.equal(activityBody.activity.some((entry) => entry.type === "command.result"), true);
});

async function connectWebSocket(url: string): Promise<WebSocket> {
  return new Promise((resolve, reject) => {
    const socket = new WebSocket(url);

    const handleOpen = () => {
      cleanup();
      resolve(socket);
    };
    const handleError = (error: Error) => {
      cleanup();
      reject(error);
    };
    const cleanup = () => {
      socket.off("open", handleOpen);
      socket.off("error", handleError);
    };

    socket.on("open", handleOpen);
    socket.on("error", handleError);
  });
}

async function closeWebSocket(socket: WebSocket): Promise<void> {
  if (socket.readyState === WebSocket.CLOSED) {
    return;
  }

  await new Promise<void>((resolve) => {
    const finalize = () => {
      socket.off("close", finalize);
      resolve();
    };

    socket.on("close", finalize);
    socket.close();
  });
}

function sendEnvelope<TPayload>(socket: WebSocket, envelope: RaikoEnvelope<TPayload>): void {
  socket.send(JSON.stringify(envelope));
}

async function waitForEnvelope(
  socket: WebSocket,
  predicate: (envelope: RaikoEnvelope<unknown>) => boolean,
): Promise<RaikoEnvelope<unknown>> {
  return new Promise((resolve, reject) => {
    const handleMessage = (raw: RawData) => {
      try {
        const envelope = JSON.parse(raw.toString()) as RaikoEnvelope<unknown>;
        if (!predicate(envelope)) {
          return;
        }

        cleanup();
        resolve(envelope);
      } catch (error) {
        cleanup();
        reject(error);
      }
    };
    const handleClose = () => {
      cleanup();
      reject(new Error("Socket closed before the expected message arrived."));
    };
    const handleError = (error: Error) => {
      cleanup();
      reject(error);
    };
    const cleanup = () => {
      socket.off("message", handleMessage);
      socket.off("close", handleClose);
      socket.off("error", handleError);
    };

    socket.on("message", handleMessage);
    socket.on("close", handleClose);
    socket.on("error", handleError);
  });
}
