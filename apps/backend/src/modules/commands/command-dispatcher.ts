import type WebSocket from "ws";
import {
  ServerEventType,
  AgentCommand,
  type CommandDispatchPayload,
  type RaikoEnvelope,
} from "@raiko/shared-types";
import { Logger } from "../../core/logger.js";
import { DeviceRegistry } from "../devices/device-registry.js";
import type { DevicesRepository } from "../devices/devices.repository.js";

export class CommandDispatcher {
  constructor(
    private readonly registry: DeviceRegistry,
    private readonly logger: Logger,
    private readonly devicesRepository?: DevicesRepository,
  ) {}

  async dispatch(payload: CommandDispatchPayload): Promise<{ ok: boolean; message: string }> {
    const agent = this.registry.getAgent(payload.targetAgentId);

    // Handle wake_up command for offline agents
    if (payload.action === AgentCommand.WakeUp && !agent) {
      return this.handleOfflineWakeUp(payload);
    }

    if (!agent) {
      // Companion agents ({deviceId}-agent) have no socket — route to the parent device
      if (payload.targetAgentId.endsWith("-agent")) {
        const parentDeviceId = payload.targetAgentId.slice(0, -"-agent".length);
        const device = this.registry.getDevice(parentDeviceId);
        if (device) {
          return this.dispatchToSocket(device.socket, payload);
        }
      }
      return { ok: false, message: `Agent ${payload.targetAgentId} is not connected.` };
    }

    return this.dispatchToSocket(agent.socket, payload);
  }

  private dispatchToSocket(socket: WebSocket, payload: CommandDispatchPayload): { ok: boolean; message: string } {
    const event: RaikoEnvelope<CommandDispatchPayload> = {
      type: ServerEventType.CommandDispatch,
      payload,
    };

    try {
      socket.send(JSON.stringify(event));
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

  private async handleOfflineWakeUp(payload: CommandDispatchPayload): Promise<{ ok: boolean; message: string }> {
    if (!this.devicesRepository) {
      return {
        ok: false,
        message: "Wake-on-LAN is not available. Agent is offline.",
      };
    }

    try {
      const agents = await this.devicesRepository.listOnlineAgents();
      const agentRecord = agents.find((a) => a.id === payload.targetAgentId);

      // Try to find in all agents, not just online
      const targetAgent = agentRecord || (await this.getOfflineAgent(payload.targetAgentId));

      if (!targetAgent?.macAddress) {
        return {
          ok: false,
          message: `Cannot wake agent ${payload.targetAgentId}: MAC address not available.`,
        };
      }

      await this.sendWakeOnLanPacket(targetAgent.macAddress);

      this.logger.info("Wake-on-LAN packet sent", {
        commandId: payload.commandId,
        targetAgentId: payload.targetAgentId,
        macAddress: targetAgent.macAddress,
      });

      return { ok: true, message: "Wake-on-LAN packet sent." };
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      this.logger.error("Failed to send Wake-on-LAN packet", {
        commandId: payload.commandId,
        targetAgentId: payload.targetAgentId,
        error: message,
      });

      return {
        ok: false,
        message: `Failed to send Wake-on-LAN packet: ${message}`,
      };
    }
  }

  private async getOfflineAgent(agentId: string) {
    if (!this.devicesRepository) return null;
    // This would require querying offline agents too, but for now we'll rely on the registry
    return null;
  }

  private async sendWakeOnLanPacket(macAddress: string): Promise<void> {
    const { sendWakeOnLan } = await import("../../network/wol-sender.js");
    await sendWakeOnLan(macAddress);
  }
}
