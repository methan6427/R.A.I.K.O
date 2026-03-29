import type WebSocket from "ws";
import { WebSocketServer } from "ws";
import {
  AgentCommand,
  ClientEventType,
  ServerEventType,
  type AgentRegisterPayload,
  type CommandResultPayload,
  type CommandSendPayload,
  type DeviceRegisterPayload,
  type DeviceStatePayload,
  type ErrorPayload,
  type HeartbeatPayload,
  type RaikoEnvelope,
} from "@raiko/shared-types";
import type { Server } from "node:http";
import { Logger } from "../core/logger.js";
import type { ModuleContainer } from "./module-container.js";

const logger = new Logger("ws-gateway");

export function attachWebSocketGateway(server: Server, modules: ModuleContainer): void {
  const wss = new WebSocketServer({ server, path: "/ws" });

  wss.on("connection", (socket) => {
    logger.info("Socket connected");

    socket.on("message", (raw) => {
      const text = raw.toString();
      try {
        const envelope = JSON.parse(text) as RaikoEnvelope<unknown>;
        switch (envelope.type) {
          case ClientEventType.DeviceRegister: {
            const payload = envelope.payload as DeviceRegisterPayload;
            modules.registry.registerDevice({
              id: payload.deviceId,
              name: payload.name,
              platform: payload.platform,
              kind: payload.kind,
              socket,
            });
            modules.activity.track("device.register", payload.deviceId, payload.name);
            send(socket, ServerEventType.Ack, {
              message: `Device ${payload.name} registered.`,
            });
            broadcastState(modules);
            break;
          }
          case ClientEventType.AgentRegister: {
            const payload = envelope.payload as AgentRegisterPayload;
            modules.registry.registerAgent({
              id: payload.agentId,
              name: payload.name,
              platform: payload.platform,
              socket,
            });
            modules.activity.track("agent.register", payload.agentId, payload.name);
            send(socket, ServerEventType.Ack, {
              message: `Agent ${payload.name} registered.`,
            });
            broadcastState(modules);
            break;
          }
          case ClientEventType.CommandSend: {
            const payload = envelope.payload as CommandSendPayload;
            if (!Object.values(AgentCommand).includes(payload.action)) {
              sendError(socket, `Unsupported command: ${payload.action}`);
              return;
            }

            const result = modules.commands.commandDispatcher.dispatch(payload);
            if (!result.ok) {
              sendError(socket, result.message);
            } else {
              send(socket, ServerEventType.Ack, { message: result.message });
            }
            break;
          }
          case ClientEventType.CommandResult: {
            const payload = envelope.payload as CommandResultPayload;
            modules.commands.commandDispatcher.broadcastResult(payload, socket);
            break;
          }
          case ClientEventType.Heartbeat: {
            const payload = envelope.payload as HeartbeatPayload;
            modules.activity.track("heartbeat", payload.clientId, payload.status);
            break;
          }
          default:
            sendError(socket, `Unknown event type: ${String(envelope.type)}`);
        }
      } catch (error) {
        sendError(socket, error instanceof Error ? error.message : "Invalid payload");
      }
    });

    socket.on("close", () => {
      modules.registry.unregisterSocket(socket);
      modules.activity.track("socket.close", "unknown", "Socket disconnected");
      broadcastState(modules);
      logger.info("Socket disconnected");
    });
  });
}

function broadcastState(modules: ModuleContainer): void {
  const payload: DeviceStatePayload = {
    devices: modules.devices.listDevices(),
    agents: modules.devices.listAgents(),
  };

  const event: RaikoEnvelope<DeviceStatePayload> = {
    type: ServerEventType.DeviceState,
    payload,
  };

  const serialized = JSON.stringify(event);
  for (const socket of modules.registry.listClientSockets()) {
    if (socket.readyState === socket.OPEN) {
      socket.send(serialized);
    }
  }
}

function send<TPayload>(socket: WebSocket, type: ServerEventType, payload: TPayload): void {
  const event: RaikoEnvelope<TPayload> = { type, payload };
  socket.send(JSON.stringify(event));
}

function sendError(socket: WebSocket, message: string): void {
  const payload: ErrorPayload = { message };
  send(socket, ServerEventType.Error, payload);
}