import WebSocket from "ws";
import {
  ServerEventType,
  type CommandDispatchPayload,
  type CommandResultPayload,
  type CommandSendPayload,
  type RaikoEnvelope,
} from "@raiko/shared-types";
import { Logger } from "../../core/logger.js";
import { ActivityModule } from "../activity/activity.module.js";
import { DeviceRegistry } from "../devices/device-registry.js";

export class CommandDispatcher {
  private readonly logger = new Logger("commands");

  constructor(
    private readonly registry: DeviceRegistry,
    private readonly activity: ActivityModule,
  ) {}

  dispatch(payload: CommandSendPayload): { ok: boolean; message: string } {
    const agent = this.registry.getAgent(payload.targetAgentId);
    if (!agent) {
      return { ok: false, message: `Agent ${payload.targetAgentId} is not connected.` };
    }

    const dispatchPayload: CommandDispatchPayload = {
      commandId: payload.commandId,
      sourceDeviceId: payload.sourceDeviceId,
      targetAgentId: payload.targetAgentId,
      action: payload.action,
      createdAt: new Date().toISOString(),
      ...(payload.args ? { args: payload.args } : {}),
    };

    const event: RaikoEnvelope<CommandDispatchPayload> = {
      type: ServerEventType.CommandDispatch,
      payload: dispatchPayload,
    };

    agent.socket.send(JSON.stringify(event));
    this.activity.track("command.dispatch", payload.sourceDeviceId, `${payload.action} -> ${payload.targetAgentId}`);
    this.logger.info("Command dispatched", {
      commandId: payload.commandId,
      targetAgentId: payload.targetAgentId,
      action: payload.action,
    });

    return { ok: true, message: "Command dispatched." };
  }

  broadcastResult(payload: CommandResultPayload, except?: WebSocket): void {
    const event: RaikoEnvelope<CommandResultPayload> = {
      type: ServerEventType.CommandResult,
      payload,
    };

    const serialized = JSON.stringify(event);
    for (const socket of this.registry.listClientSockets()) {
      if (socket !== except && socket.readyState === WebSocket.OPEN) {
        socket.send(serialized);
      }
    }

    this.activity.track("command.result", payload.agentId, `${payload.action} => ${payload.status}`);
  }
}