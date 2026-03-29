import assert from "node:assert/strict";
import type { AddressInfo } from "node:net";
import test from "node:test";
import WebSocket, { type ClientOptions, type RawData } from "ws";
import {
  AgentCommand,
  ClientEventType,
  ServerEventType,
  type CommandDispatchPayload,
  type CommandLogEntry,
  type CommandResultPayload,
  type DeviceSummary,
  type RaikoEnvelope,
} from "@raiko/shared-types";
import type { BackendConfig } from "../config/env.js";
import { Logger } from "../core/logger.js";
import { createInMemoryDatabase } from "../database/test-database.js";
import { createApp } from "./create-app.js";

interface ConnectionStateRow {
  status: "online" | "offline";
  last_seen_at: string | Date;
  disconnected_at: string | Date | null;
}

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

test("startup reconciliation marks stale persisted devices and agents offline until they reconnect", async () => {
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

  await database.migrate();
  await database.query(
    `
      INSERT INTO users (id, email, display_name, updated_at)
      VALUES ($1, $2, $3, NOW())
    `,
    [config.bootstrapUser.id, config.bootstrapUser.email, config.bootstrapUser.displayName],
  );

  const staleLastSeenAt = "2026-03-29T09:30:00.000Z";
  await database.query(
    `
      INSERT INTO devices (
        id,
        user_id,
        name,
        platform,
        kind,
        status,
        connected_at,
        last_seen_at,
        updated_at
      )
      VALUES ($1, $2, $3, $4, $5, 'online', $6, $7, NOW())
    `,
    [
      "mobile-01",
      config.bootstrapUser.id,
      "Operator Phone",
      "android",
      "mobile",
      "2026-03-29T09:00:00.000Z",
      staleLastSeenAt,
    ],
  );
  await database.query(
    `
      INSERT INTO agents (
        id,
        name,
        platform,
        status,
        supported_commands,
        connected_at,
        last_seen_at,
        updated_at
      )
      VALUES ($1, $2, $3, 'online', $4, $5, $6, NOW())
    `,
    [
      "agent-01",
      "Windows Agent",
      "windows",
      JSON.stringify([AgentCommand.Lock]),
      "2026-03-29T09:00:00.000Z",
      staleLastSeenAt,
    ],
  );

  const appBundle = await createApp(
    {
      ...config,
      runMigrations: false,
    },
    {
      logger,
      database,
    },
  );

  let deviceSocket: WebSocket | undefined;
  let agentSocket: WebSocket | undefined;

  try {
    appBundle.attachGateway();
    await appBundle.app.listen({
      host: "127.0.0.1",
      port: 0,
    });

    const devicesResponse = await appBundle.app.inject({
      method: "GET",
      url: "/api/devices",
      headers: {
        "x-raiko-token": config.authToken!,
      },
    });
    const agentsResponse = await appBundle.app.inject({
      method: "GET",
      url: "/api/agents",
      headers: {
        "x-raiko-token": config.authToken!,
      },
    });

    assert.deepEqual(JSON.parse(devicesResponse.body), { devices: [] });
    assert.deepEqual(JSON.parse(agentsResponse.body), { agents: [] });

    const deviceRowResult = await database.query<ConnectionStateRow>(
      `
        SELECT status, last_seen_at, disconnected_at
        FROM devices
        WHERE id = $1
      `,
      ["mobile-01"],
    );
    const agentRowResult = await database.query<ConnectionStateRow>(
      `
        SELECT status, last_seen_at, disconnected_at
        FROM agents
        WHERE id = $1
      `,
      ["agent-01"],
    );

    assert.equal(deviceRowResult.rows[0]?.status, "offline");
    assert.equal(new Date(deviceRowResult.rows[0]!.last_seen_at).toISOString(), staleLastSeenAt);
    assert.notEqual(deviceRowResult.rows[0]?.disconnected_at, null);
    assert.equal(agentRowResult.rows[0]?.status, "offline");
    assert.equal(new Date(agentRowResult.rows[0]!.last_seen_at).toISOString(), staleLastSeenAt);
    assert.notEqual(agentRowResult.rows[0]?.disconnected_at, null);

    const address = appBundle.app.server.address();
    assert.notEqual(address, null);
    assert.equal(typeof address, "object");

    const wsUrl = `ws://127.0.0.1:${(address as AddressInfo).port}/ws?token=${config.authToken!}`;
    deviceSocket = await connectWebSocket(wsUrl);
    agentSocket = await connectWebSocket(wsUrl);

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

    const refreshedDevicesResponse = await appBundle.app.inject({
      method: "GET",
      url: "/api/devices",
      headers: {
        "x-raiko-token": config.authToken!,
      },
    });
    const refreshedAgentsResponse = await appBundle.app.inject({
      method: "GET",
      url: "/api/agents",
      headers: {
        "x-raiko-token": config.authToken!,
      },
    });

    assert.equal((JSON.parse(refreshedDevicesResponse.body) as { devices: DeviceSummary[] }).devices[0]?.id, "mobile-01");
    assert.equal((JSON.parse(refreshedAgentsResponse.body) as { agents: DeviceSummary[] }).agents[0]?.id, "agent-01");
  } finally {
    await closeWebSocket(deviceSocket).catch(() => undefined);
    await closeWebSocket(agentSocket).catch(() => undefined);
    await appBundle.app.close().catch(() => undefined);
    await database.close().catch(() => undefined);
  }
});

test("unknown command results are rejected without broadcast or activity and emit a warning", async () => {
  const logEntries: Array<Record<string, unknown>> = [];
  const logger = new Logger("test", {
    minLevel: "debug",
    sink: (entry) => {
      logEntries.push(JSON.parse(entry) as Record<string, unknown>);
    },
  });
  const database = createInMemoryDatabase(logger);
  const config: BackendConfig = {
    environment: "test",
    host: "127.0.0.1",
    port: 0,
    authToken: "integration-secret",
    activityLimit: 50,
    commandLimit: 50,
    logLevel: "debug",
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

  const appBundle = await createApp(config, {
    logger,
    database,
  });
  let observerSocket: WebSocket | undefined;
  let agentSocket: WebSocket | undefined;

  try {
    appBundle.attachGateway();
    await appBundle.app.listen({
      host: "127.0.0.1",
      port: 0,
    });

    const address = appBundle.app.server.address();
    assert.notEqual(address, null);
    assert.equal(typeof address, "object");

    const wsUrl = `ws://127.0.0.1:${(address as AddressInfo).port}/ws?token=${config.authToken!}`;
    observerSocket = await connectWebSocket(wsUrl);
    agentSocket = await connectWebSocket(wsUrl);

    const observerAckPromise = waitForEnvelope(observerSocket, (envelope) => envelope.type === ServerEventType.Ack);
    sendEnvelope(observerSocket, {
      type: ClientEventType.DeviceRegister,
      payload: {
        deviceId: "mobile-01",
        name: "Operator Phone",
        platform: "android",
        kind: "mobile",
      },
    });
    await observerAckPromise;

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

    sendEnvelope(agentSocket, {
      type: ClientEventType.CommandResult,
      payload: {
        commandId: "missing-command",
        agentId: "agent-01",
        action: AgentCommand.Lock,
        status: "success",
        output: "done",
        completedAt: "2026-03-29T10:10:00.000Z",
      },
    });

    await assertNoEnvelope(
      observerSocket,
      (envelope) =>
        envelope.type === ServerEventType.CommandResult &&
        (envelope.payload as CommandResultPayload).commandId === "missing-command",
    );

    const commandsResponse = await appBundle.app.inject({
      method: "GET",
      url: "/api/commands",
      headers: {
        "x-raiko-token": config.authToken!,
      },
    });
    const commandsBody = JSON.parse(commandsResponse.body) as {
      commands: CommandLogEntry[];
    };
    assert.deepEqual(commandsBody.commands, []);

    const activityResponse = await appBundle.app.inject({
      method: "GET",
      url: "/api/activity",
      headers: {
        "x-raiko-token": config.authToken!,
      },
    });
    const activityBody = JSON.parse(activityResponse.body) as {
      activity: Array<{ type: string }>;
    };
    assert.equal(activityBody.activity.some((entry) => entry.type === "command.result"), false);

    const warningLog = logEntries.find(
      (entry) =>
        entry.level === "warn" &&
        entry.message === "Rejected unknown command result" &&
        typeof entry.meta === "object" &&
        entry.meta !== null &&
        (entry.meta as Record<string, unknown>).commandId === "missing-command",
    );
    assert.notEqual(warningLog, undefined);
  } finally {
    await closeWebSocket(observerSocket).catch(() => undefined);
    await closeWebSocket(agentSocket).catch(() => undefined);
    await appBundle.app.close().catch(() => undefined);
    await database.close().catch(() => undefined);
  }
});

test("mobile websocket registration via auth header does not push dashboard snapshots onto agent sockets", async () => {
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

  const appBundle = await createApp(config, {
    logger,
    database,
  });
  let agentSocket: WebSocket | undefined;
  let firstMobileSocket: WebSocket | undefined;
  let secondMobileSocket: WebSocket | undefined;

  try {
    appBundle.attachGateway();
    await appBundle.app.listen({
      host: "127.0.0.1",
      port: 0,
    });

    const address = appBundle.app.server.address();
    assert.notEqual(address, null);
    assert.equal(typeof address, "object");

    const port = (address as AddressInfo).port;
    const wsUrl = `ws://127.0.0.1:${port}/ws`;

    agentSocket = await connectWebSocket(`${wsUrl}?token=${config.authToken!}`);
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

    firstMobileSocket = await connectWebSocket(wsUrl, {
      headers: {
        "x-raiko-token": config.authToken!,
      },
    });
    const firstMobileAckPromise = waitForEnvelope(
      firstMobileSocket,
      (envelope) => envelope.type === ServerEventType.Ack,
    );
    const firstMobileSnapshotPromise = waitForEnvelope(
      firstMobileSocket,
      (envelope) =>
        envelope.type === ServerEventType.DeviceState &&
        (envelope.payload as { agents: Array<{ id: string }> }).agents.some((agent) => agent.id === "agent-01"),
    );
    sendEnvelope(firstMobileSocket, {
      type: ClientEventType.DeviceRegister,
      payload: {
        deviceId: "mobile-01",
        name: "Operator Phone",
        platform: "android",
        kind: "mobile",
      },
    });
    await firstMobileAckPromise;
    await firstMobileSnapshotPromise;
    await assertNoEnvelope(
      agentSocket,
      (envelope) =>
        envelope.type === ServerEventType.DeviceState ||
        envelope.type === ServerEventType.ActivitySnapshot ||
        envelope.type === ServerEventType.CommandSnapshot,
    );
    assert.equal(agentSocket.readyState, WebSocket.OPEN);

    await closeWebSocket(firstMobileSocket);
    firstMobileSocket = undefined;

    secondMobileSocket = await connectWebSocket(wsUrl, {
      headers: {
        "x-raiko-token": config.authToken!,
      },
    });
    const secondMobileAckPromise = waitForEnvelope(
      secondMobileSocket,
      (envelope) => envelope.type === ServerEventType.Ack,
    );
    sendEnvelope(secondMobileSocket, {
      type: ClientEventType.DeviceRegister,
      payload: {
        deviceId: "mobile-01",
        name: "Operator Phone",
        platform: "android",
        kind: "mobile",
      },
    });
    await secondMobileAckPromise;
    await assertNoEnvelope(
      agentSocket,
      (envelope) =>
        envelope.type === ServerEventType.DeviceState ||
        envelope.type === ServerEventType.ActivitySnapshot ||
        envelope.type === ServerEventType.CommandSnapshot,
    );
    assert.equal(agentSocket.readyState, WebSocket.OPEN);
  } finally {
    await closeWebSocket(secondMobileSocket).catch(() => undefined);
    await closeWebSocket(firstMobileSocket).catch(() => undefined);
    await closeWebSocket(agentSocket).catch(() => undefined);
    await appBundle.app.close().catch(() => undefined);
    await database.close().catch(() => undefined);
  }
});

async function connectWebSocket(url: string, options?: ClientOptions): Promise<WebSocket> {
  return new Promise((resolve, reject) => {
    const socket = new WebSocket(url, options);

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

async function closeWebSocket(socket?: WebSocket): Promise<void> {
  if (!socket || socket.readyState === WebSocket.CLOSED || socket.readyState === WebSocket.CLOSING) {
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

async function assertNoEnvelope(
  socket: WebSocket,
  predicate: (envelope: RaikoEnvelope<unknown>) => boolean,
  timeoutMs = 250,
): Promise<void> {
  return new Promise((resolve, reject) => {
    const handleMessage = (raw: RawData) => {
      try {
        const envelope = JSON.parse(raw.toString()) as RaikoEnvelope<unknown>;
        if (!predicate(envelope)) {
          return;
        }

        cleanup();
        reject(new Error(`Received unexpected envelope: ${JSON.stringify(envelope)}`));
      } catch (error) {
        cleanup();
        reject(error);
      }
    };
    const handleClose = () => {
      cleanup();
      resolve();
    };
    const handleError = (error: Error) => {
      cleanup();
      reject(error);
    };
    const cleanup = () => {
      clearTimeout(timer);
      socket.off("message", handleMessage);
      socket.off("close", handleClose);
      socket.off("error", handleError);
    };
    const timer = setTimeout(() => {
      cleanup();
      resolve();
    }, timeoutMs);

    socket.on("message", handleMessage);
    socket.on("close", handleClose);
    socket.on("error", handleError);
  });
}
