import assert from "node:assert/strict";
import test from "node:test";
import { AgentCommand, type CommandDispatchPayload } from "@raiko/shared-types";
import { buildExecutionPlan, handleCommand } from "./command-handlers.js";

function createPayload(
  action: AgentCommand,
  args?: Record<string, unknown>,
): CommandDispatchPayload {
  return {
    commandId: "cmd-1",
    sourceDeviceId: "mobile-01",
    targetAgentId: "agent-01",
    action,
    createdAt: "2026-03-29T10:00:00.000Z",
    ...(args ? { args } : {}),
  };
}

test("buildExecutionPlan maps lock to the expected Windows command", () => {
  const plan = buildExecutionPlan(createPayload(AgentCommand.Lock));

  assert.deepEqual(plan, {
    command: "rundll32.exe",
    args: ["user32.dll,LockWorkStation"],
    summary: "Executed rundll32.exe user32.dll,LockWorkStation",
  });
});

test("buildExecutionPlan validates open_app arguments", () => {
  assert.throws(
    () => buildExecutionPlan(createPayload(AgentCommand.OpenApp)),
    /open_app requires args.path/,
  );
});

test("handleCommand supports dry-run execution", async () => {
  const result = await handleCommand(createPayload(AgentCommand.Sleep), {
    dryRun: true,
  });

  assert.equal(result.status, "success");
  assert.match(result.output, /Dry run:/);
});
