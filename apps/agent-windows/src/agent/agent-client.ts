import WebSocket from "ws";
import {
  ClientEventType,
  ServerEventType,
  type AgentRegisterPayload,
  type CommandDispatchPayload,
  type HeartbeatPayload,
  type RaikoEnvelope,
} from "@raiko/shared-types";
import type { AgentConfig } from "../config.js";
import { AgentLogger } from "../logger.js";
import { handleCommand } from "../commands/command-handlers.js";

export class AgentClient {
  private socket?: WebSocket;
  private heartbeatTimer: NodeJS.Timeout | undefined;

  constructor(
    private readonly config: AgentConfig,
    private readonly logger: AgentLogger,
  ) {}

  connect(): void {
    this.socket = new WebSocket(this.config.backendUrl);

    this.socket.on("open", () => {
      this.logger.info("Connected to backend", { url: this.config.backendUrl });
      this.register();
      this.startHeartbeat();
    });

    this.socket.on("message", async (raw) => {
      const envelope = JSON.parse(raw.toString()) as RaikoEnvelope<unknown>;
      if (envelope.type === ServerEventType.CommandDispatch) {
        const payload = envelope.payload as CommandDispatchPayload;
        this.logger.info("Command received", {
          commandId: payload.commandId,
          action: payload.action,
        });

        const result = await handleCommand(payload);
        this.send(ClientEventType.CommandResult, result);
        this.logger.info("Command processed", {
          commandId: result.commandId,
          status: result.status,
          output: result.output,
        });
      }
    });

    this.socket.on("close", () => {
      this.logger.error("Connection closed. Reconnecting in 5s.");
      this.stopHeartbeat();
      setTimeout(() => this.connect(), 5000);
    });

    this.socket.on("error", (error) => {
      this.logger.error("Socket error", { message: error.message });
    });
  }

  private register(): void {
    const payload: AgentRegisterPayload = {
      agentId: this.config.agentId,
      name: this.config.agentName,
      platform: this.config.platform,
    };

    this.send(ClientEventType.AgentRegister, payload);
  }

  private startHeartbeat(): void {
    this.heartbeatTimer = setInterval(() => {
      const payload: HeartbeatPayload = {
        clientId: this.config.agentId,
        status: "online",
        sentAt: new Date().toISOString(),
      };

      this.send(ClientEventType.Heartbeat, payload);
    }, 15000);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = undefined;
    }
  }

  private send<TPayload>(type: ClientEventType, payload: TPayload): void {
    if (!this.socket || this.socket.readyState !== WebSocket.OPEN) {
      return;
    }

    const event: RaikoEnvelope<TPayload> = { type, payload };
    this.socket.send(JSON.stringify(event));
  }
}