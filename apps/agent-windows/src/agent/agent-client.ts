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
  private socket: WebSocket | undefined;
  private heartbeatTimer: NodeJS.Timeout | undefined;

  constructor(
    private readonly config: AgentConfig,
    private readonly logger: AgentLogger,
  ) {}

  connect(): void {
    this.socket = new WebSocket(this.config.backendUrl, {
      ...(this.config.authToken ? { headers: { "x-raiko-token": this.config.authToken } } : {}),
    });

    this.socket.on("open", () => {
      this.logger.info("Connected to backend", { url: this.config.backendUrl });
      this.register();
      this.startHeartbeat();
    });

    this.socket.on("message", async (raw) => {
      const envelope = this.parseEnvelope(raw.toString());
      if (!envelope) {
        return;
      }

      switch (envelope.type) {
        case ServerEventType.Ack:
          this.logger.info("Backend acknowledged event", envelope.payload as Record<string, unknown>);
          break;
        case ServerEventType.Error:
          this.logger.error("Backend returned error", envelope.payload as Record<string, unknown>);
          break;
        case ServerEventType.CommandDispatch: {
          const payload = envelope.payload as CommandDispatchPayload;
          this.logger.info("Command received", {
            commandId: payload.commandId,
            action: payload.action,
          });

          const result = await handleCommand(payload, {
            dryRun: this.config.dryRun,
          });
          this.send(ClientEventType.CommandResult, result);
          this.logger.info("Command processed", {
            commandId: result.commandId,
            status: result.status,
            output: result.output,
          });
          break;
        }
        default:
          this.logger.info("Ignoring server event", { type: envelope.type });
      }
    });

    this.socket.on("close", () => {
      this.logger.error("Connection closed. Reconnecting.", {
        delayMs: this.config.reconnectDelayMs,
      });
      this.stopHeartbeat();
      this.socket = undefined;
      setTimeout(() => this.connect(), this.config.reconnectDelayMs);
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
      supportedCommands: this.config.supportedCommands,
    };

    this.send(ClientEventType.AgentRegister, payload);
  }

  private startHeartbeat(): void {
    this.stopHeartbeat();
    this.heartbeatTimer = setInterval(() => {
      const payload: HeartbeatPayload = {
        clientId: this.config.agentId,
        status: "online",
        sentAt: new Date().toISOString(),
      };

      this.send(ClientEventType.Heartbeat, payload);
    }, this.config.heartbeatIntervalMs);
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

  private parseEnvelope(raw: string): RaikoEnvelope<unknown> | undefined {
    try {
      return JSON.parse(raw) as RaikoEnvelope<unknown>;
    } catch (error) {
      this.logger.error("Failed to parse backend payload", {
        message: error instanceof Error ? error.message : String(error),
      });
      return undefined;
    }
  }
}
