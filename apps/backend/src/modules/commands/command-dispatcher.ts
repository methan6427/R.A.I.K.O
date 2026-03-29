import {
  ServerEventType,
  type CommandDispatchPayload,
  type RaikoEnvelope,
} from "@raiko/shared-types";
import { Logger } from "../../core/logger.js";
import { DeviceRegistry } from "../devices/device-registry.js";

export class CommandDispatcher {
  constructor(
    private readonly registry: DeviceRegistry,
    private readonly logger: Logger,
  ) {}

  dispatch(payload: CommandDispatchPayload): { ok: boolean; message: string } {
    const agent = this.registry.getAgent(payload.targetAgentId);
    if (!agent) {
      return { ok: false, message: `Agent ${payload.targetAgentId} is not connected.` };
    }

    const event: RaikoEnvelope<CommandDispatchPayload> = {
      type: ServerEventType.CommandDispatch,
      payload,
    };

    try {
      agent.socket.send(JSON.stringify(event));
      this.logger.info("Command dispatched", {
        commandId: payload.commandId,
        targetAgentId: payload.targetAgentId,
        action: payload.action,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown socket dispatch error";
      this.logger.warn("Command dispatch failed", {
        commandId: payload.commandId,
        targetAgentId: payload.targetAgentId,
        action: payload.action,
        reason: message,
      });

      return {
        ok: false,
        message: `Failed to dispatch command to ${payload.targetAgentId}: ${message}`,
      };
    }

    return { ok: true, message: "Command dispatched." };
  }
}
