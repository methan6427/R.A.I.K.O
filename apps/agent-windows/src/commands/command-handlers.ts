import { spawn } from "node:child_process";
import { AgentCommand, type CommandDispatchPayload, type CommandResultPayload } from "@raiko/shared-types";

export interface CommandHandlerOptions {
  dryRun?: boolean;
}

interface CommandExecutionPlan {
  command: string;
  args: string[];
  summary: string;
}

export async function handleCommand(
  payload: CommandDispatchPayload,
  options: CommandHandlerOptions = {},
): Promise<CommandResultPayload> {
  try {
    const plan = buildExecutionPlan(payload);
    if (!plan) {
      return result(payload, "failed", `Unsupported action: ${payload.action}`);
    }

    if (options.dryRun) {
      return result(payload, "success", `Dry run: ${plan.summary}`);
    }

    await executeWindowsCommand(plan.command, plan.args);
    return result(payload, "success", plan.summary);
  } catch (error) {
    return result(
      payload,
      "failed",
      error instanceof Error ? error.message : `Command failed: ${String(error)}`,
    );
  }
}

export function buildExecutionPlan(payload: CommandDispatchPayload): CommandExecutionPlan | undefined {
  switch (payload.action) {
    case AgentCommand.Shutdown:
      return {
        command: "shutdown.exe",
        args: ["/s", "/t", "0", "/f"],
        summary: "Executed shutdown.exe /s /t 0 /f",
      };
    case AgentCommand.Restart:
      return {
        command: "shutdown.exe",
        args: ["/r", "/t", "0", "/f"],
        summary: "Executed shutdown.exe /r /t 0 /f",
      };
    case AgentCommand.Sleep:
      return {
        command: "rundll32.exe",
        args: ["powrprof.dll,SetSuspendState", "0,1,0"],
        summary: "Executed rundll32.exe powrprof.dll,SetSuspendState 0,1,0",
      };
    case AgentCommand.Lock:
      return {
        command: "rundll32.exe",
        args: ["user32.dll,LockWorkStation"],
        summary: "Executed rundll32.exe user32.dll,LockWorkStation",
      };
    case AgentCommand.OpenApp: {
      const path = payload.args?.path;
      const additionalArgs = payload.args?.arguments;
      if (typeof path !== "string" || path.trim().length === 0) {
        throw new Error("open_app requires args.path");
      }

      const normalizedArgs = Array.isArray(additionalArgs)
        ? additionalArgs.filter((item): item is string => typeof item === "string")
        : [];

      return {
        command: path,
        args: normalizedArgs,
        summary: `Executed ${path}${normalizedArgs.length > 0 ? ` ${normalizedArgs.join(" ")}` : ""}`,
      };
    }
    default:
      return undefined;
  }
}

async function executeWindowsCommand(command: string, args: string[]): Promise<void> {
  await new Promise<void>((resolve, reject) => {
    const child = spawn(command, args, {
      detached: true,
      shell: false,
      stdio: "ignore",
      windowsHide: true,
    });

    child.once("error", reject);
    child.once("spawn", () => {
      child.unref();
      resolve();
    });
  });
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
