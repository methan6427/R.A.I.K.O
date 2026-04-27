import type { IncomingMessage } from "node:http";
import type { Server } from "node:http";
import type WebSocket from "ws";
import { WebSocketServer } from "ws";
import {
  AgentCommand,
  ClientEventType,
  ServerEventType,
  type AckPayload,
  type ActivitySnapshotPayload,
  type AgentRegisterPayload,
  type CommandResultPayload,
  type CommandSendPayload,
  type CommandSnapshotPayload,
  type DeviceRegisterPayload,
  type DeviceStatePayload,
  type ErrorPayload,
  type HeartbeatPayload,
  type RaikoEnvelope,
} from "@raiko/shared-types";
import { Logger } from "../core/logger.js";
import type { ModuleContainer } from "./module-container.js";

export function attachWebSocketGateway(
  server: Server,
  modules: ModuleContainer,
  logger: Logger,
): void {
  const wss = new WebSocketServer({
    server,
    path: "/ws",
    // Reject unauthorized handshakes before the upgrade completes so failed auth
    // attempts don't consume CPU/RAM for a TCP+TLS+WS round-trip just to be closed.
    verifyClient: (info, done) => {
      if (isAuthorizedConnection(modules, info.req)) {
        done(true);
        return;
      }
      logger.warn("Rejected websocket upgrade due to invalid token", {
        remoteAddress: info.req.socket.remoteAddress,
      });
      done(false, 401, "Unauthorized");
    },
  });

  wss.on("connection", (socket, request) => {
    logger.info("Socket connected", {
      remoteAddress: request.socket.remoteAddress,
    });

    socket.on("message", (raw) => {
      void handleMessage(modules, socket, raw.toString(), logger).catch((error) => {
        logger.error("Failed to handle websocket message", serializeError(error));
        sendError(socket, error instanceof Error ? error.message : "Invalid payload");
      });
    });

    socket.on("close", () => {
      void handleClose(modules, socket, logger).catch((error) => {
        logger.error("Failed to persist websocket disconnect", serializeError(error));
      });
    });
  });
}

async function handleMessage(
  modules: ModuleContainer,
  socket: WebSocket,
  text: string,
  logger: Logger,
): Promise<void> {
  const envelope = JSON.parse(text) as RaikoEnvelope<unknown>;

  switch (envelope.type) {
    case ClientEventType.DeviceRegister: {
      const payload = envelope.payload as DeviceRegisterPayload;
      await modules.devices.registerDevice(payload, socket);
      await modules.activity.track("device.register", payload.deviceId, payload.name);
      sendAck(socket, `Device ${payload.name} registered.`);
      await broadcastSnapshots(modules);
      return;
    }
    case ClientEventType.AgentRegister: {
      const payload = envelope.payload as AgentRegisterPayload;
      await modules.devices.registerAgent(payload, socket);
      await modules.activity.track("agent.register", payload.agentId, payload.name);
      sendAck(socket, `Agent ${payload.name} registered.`);
      await broadcastSnapshots(modules);
      return;
    }
    case ClientEventType.CommandSend: {
      const payload = envelope.payload as CommandSendPayload;
      if (!isAgentCommand(payload.action)) {
        sendError(socket, `Unsupported command: ${String(payload.action)}`);
        return;
      }

      const result = await modules.commands.dispatch(payload);
      if (!result.ok) {
        sendError(socket, result.message);
      } else {
        sendAck(socket, result.message);
      }

      await broadcastSnapshots(modules);
      return;
    }
    case ClientEventType.CommandResult: {
      const payload = envelope.payload as CommandResultPayload;
      const recorded = await modules.commands.recordResult(payload);
      if (!recorded) {
        logger.warn("Rejected unknown command result", {
          commandId: payload.commandId,
          agentId: payload.agentId,
          action: payload.action,
          status: payload.status,
        });
        return;
      }

      broadcastCommandResult(modules, payload, socket);
      await broadcastSnapshots(modules);
      return;
    }
    case ClientEventType.Heartbeat: {
      const payload = envelope.payload as HeartbeatPayload;
      await modules.devices.markHeartbeat(payload.clientId, payload.status, payload.sentAt);
      await modules.activity.track("heartbeat", payload.clientId, payload.status);
      await broadcastSnapshots(modules);
      return;
    }
    default:
      sendError(socket, `Unknown event type: ${String(envelope.type)}`);
  }
}

async function handleClose(modules: ModuleContainer, socket: WebSocket, logger: Logger): Promise<void> {
  const disconnected = modules.registry.unregisterSocket(socket);
  if (disconnected) {
    const disconnectedAt = new Date().toISOString();
    await modules.devices.markDisconnected(disconnected, disconnectedAt);
    await modules.activity.track(`${disconnected.kind}.disconnect`, disconnected.id, disconnected.name);
  } else {
    await modules.activity.track("socket.close", "unknown", "Socket disconnected");
  }

  await broadcastSnapshots(modules);
  logger.info("Socket disconnected");
}

async function broadcastSnapshots(modules: ModuleContainer): Promise<void> {
  const [devices, agents, activityEntries, commandEntries] = await Promise.all([
    Promise.resolve(modules.devices.listDevices()),
    modules.devices.listAgents(),
    modules.activity.list(),
    modules.commands.list(),
  ]);

  const deviceState: DeviceStatePayload = {
    devices,
    agents,
  };
  const activity: ActivitySnapshotPayload = {
    activity: activityEntries,
  };
  const commands: CommandSnapshotPayload = {
    commands: commandEntries,
  };

  broadcastToDevices(modules, ServerEventType.DeviceState, deviceState);
  broadcastToDevices(modules, ServerEventType.ActivitySnapshot, activity);
  broadcastToDevices(modules, ServerEventType.CommandSnapshot, commands);
}

function broadcastCommandResult(
  modules: ModuleContainer,
  payload: CommandResultPayload,
  except?: WebSocket,
): void {
  broadcastToDevices(modules, ServerEventType.CommandResult, payload, except);
}

function broadcastToDevices<TPayload>(
  modules: ModuleContainer,
  type: ServerEventType,
  payload: TPayload,
  except?: WebSocket,
): void {
  broadcast(modules.registry.listDeviceSockets(), type, payload, except);
}

function broadcast<TPayload>(
  sockets: WebSocket[],
  type: ServerEventType,
  payload: TPayload,
  except?: WebSocket,
): void {
  const serialized = JSON.stringify({
    type,
    payload,
  } satisfies RaikoEnvelope<TPayload>);

  for (const socket of sockets) {
    if (socket !== except && socket.readyState === socket.OPEN) {
      socket.send(serialized);
    }
  }
}

function send<TPayload>(socket: WebSocket, type: ServerEventType, payload: TPayload): void {
  const event: RaikoEnvelope<TPayload> = { type, payload };
  socket.send(JSON.stringify(event));
}

function sendAck(socket: WebSocket, message: string): void {
  const payload: AckPayload = { message };
  send(socket, ServerEventType.Ack, payload);
}

function sendError(socket: WebSocket, message: string): void {
  const payload: ErrorPayload = { message };
  send(socket, ServerEventType.Error, payload);
}

function isAuthorizedConnection(modules: ModuleContainer, request: IncomingMessage): boolean {
  if (!modules.auth.isEnabled) {
    return true;
  }

  const url = new URL(request.url ?? "/ws", "ws://localhost");
  const token = url.searchParams.get("token") ?? request.headers["x-raiko-token"];
  return modules.auth.validateToken(token);
}

function isAgentCommand(value: unknown): value is AgentCommand {
  return Object.values(AgentCommand).includes(value as AgentCommand);
}

function serializeError(error: unknown): Record<string, unknown> {
  if (error instanceof Error) {
    return {
      name: error.name,
      message: error.message,
      stack: error.stack,
    };
  }

  return {
    error,
  };
}
