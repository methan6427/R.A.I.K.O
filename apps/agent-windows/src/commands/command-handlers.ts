import { AgentCommand, type CommandDispatchPayload, type CommandResultPayload } from "@raiko/shared-types";

export async function handleCommand(payload: CommandDispatchPayload): Promise<CommandResultPayload> {
  switch (payload.action) {
    case AgentCommand.Shutdown:
      return result(payload, "success", "Shutdown scheduled (skeleton).");
    case AgentCommand.Restart:
      return result(payload, "success", "Restart scheduled (skeleton).");
    case AgentCommand.Sleep:
      return result(payload, "success", "Sleep scheduled (skeleton).");
    case AgentCommand.Lock:
      return result(payload, "success", "Lock scheduled (skeleton).");
    case AgentCommand.OpenApp: {
      const target = typeof payload.args?.path === "string" ? payload.args.path : "unknown";
      return result(payload, "success", `Open app requested for ${target}.`);
    }
    default:
      return result(payload, "failed", `Unsupported action: ${payload.action}`);
  }
}

function result(
  payload: CommandDispatchPayload,
  status: CommandResultPayload["status"],
  output: string,
): CommandResultPayload {
  return {
    commandId: payload.commandId,
    agentId: payload.targetAgentId,
    action: payload.action,
    status,
    output,
    completedAt: new Date().toISOString(),
  };
}