import type {
  CommandDispatchPayload,
  CommandLogEntry,
  CommandResultPayload,
  CommandSendPayload,
} from "@raiko/shared-types";
import { ActivityModule } from "../activity/activity.module.js";
import type { CommandResultRecord, CommandsRepository } from "./commands.repository.js";
import { CommandDispatcher } from "./command-dispatcher.js";

export class CommandsModule {
  constructor(
    private readonly repository: CommandsRepository,
    private readonly dispatcher: CommandDispatcher,
    private readonly activity: ActivityModule,
    private readonly limit = 200,
  ) {}

  async dispatch(payload: CommandSendPayload): Promise<{ ok: boolean; message: string }> {
    const dispatchPayload: CommandDispatchPayload = {
      ...payload,
      createdAt: new Date().toISOString(),
      ...(payload.args ? { args: payload.args } : {}),
    };

    await this.repository.storePending({
      commandId: dispatchPayload.commandId,
      sourceDeviceId: dispatchPayload.sourceDeviceId,
      targetAgentId: dispatchPayload.targetAgentId,
      action: dispatchPayload.action,
      createdAt: dispatchPayload.createdAt,
      ...(dispatchPayload.args ? { args: dispatchPayload.args } : {}),
    });

    const result = this.dispatcher.dispatch(dispatchPayload);
    if (!result.ok) {
      const failedResult: CommandResultRecord = {
        commandId: dispatchPayload.commandId,
        agentId: dispatchPayload.targetAgentId,
        action: dispatchPayload.action,
        status: "failed",
        output: result.message,
        completedAt: new Date().toISOString(),
      };

      await this.repository.recordFailure(failedResult);
      await this.activity.track("command.rejected", payload.sourceDeviceId, result.message);
      return result;
    }

    await this.activity.track("command.dispatch", payload.sourceDeviceId, `${payload.action} -> ${payload.targetAgentId}`);
    return result;
  }

  async recordResult(payload: CommandResultPayload): Promise<void> {
    await this.repository.recordResult(payload);
    await this.activity.track("command.result", payload.agentId, `${payload.action} => ${payload.status}`);
  }

  async list(): Promise<CommandLogEntry[]> {
    return this.repository.listRecent(this.limit);
  }
}
