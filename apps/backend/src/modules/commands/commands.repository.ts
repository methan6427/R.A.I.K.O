import type { QueryResultRow } from "pg";
import type {
  AgentCommand,
  CommandLogEntry,
  CommandResultPayload,
  CommandExecutionStatus,
} from "@raiko/shared-types";
import type { DatabaseClient, TransactionalDatabaseClient } from "../../database/database.js";

export interface PendingCommandRecord {
  commandId: string;
  sourceDeviceId: string;
  targetAgentId: string;
  action: AgentCommand;
  args?: Record<string, unknown>;
  createdAt: string;
}

export interface CommandResultRecord {
  commandId: string;
  agentId: string;
  action: AgentCommand;
  status: Extract<CommandExecutionStatus, "success" | "failed">;
  output: string;
  completedAt: string;
}

export interface CommandsRepository {
  storePending(command: PendingCommandRecord): Promise<void>;
  recordFailure(result: CommandResultRecord): Promise<void>;
  recordResult(result: CommandResultPayload): Promise<void>;
  listRecent(limit: number): Promise<CommandLogEntry[]>;
}

interface CommandLogRow extends QueryResultRow {
  command_id: string;
  source_device_id: string;
  target_agent_id: string;
  action: AgentCommand;
  status: CommandExecutionStatus;
  args_json: Record<string, unknown> | null;
  created_at: string | Date;
  output: string | null;
  completed_at: string | Date | null;
}

export class PostgresCommandsRepository implements CommandsRepository {
  constructor(private readonly database: TransactionalDatabaseClient) {}

  async storePending(command: PendingCommandRecord): Promise<void> {
    await this.database.query(
      `
        INSERT INTO commands (
          command_id,
          source_device_id,
          target_agent_id,
          action,
          status,
          args_json,
          created_at,
          updated_at
        )
        VALUES ($1, $2, $3, $4, 'pending', $5, $6, $6)
        ON CONFLICT (command_id)
        DO UPDATE SET
          source_device_id = EXCLUDED.source_device_id,
          target_agent_id = EXCLUDED.target_agent_id,
          action = EXCLUDED.action,
          status = EXCLUDED.status,
          args_json = EXCLUDED.args_json,
          created_at = EXCLUDED.created_at,
          updated_at = EXCLUDED.updated_at
      `,
      [
        command.commandId,
        command.sourceDeviceId,
        command.targetAgentId,
        command.action,
        command.args ?? null,
        command.createdAt,
      ],
    );
  }

  async recordFailure(result: CommandResultRecord): Promise<void> {
    await this.applyCommandResult(result);
  }

  async recordResult(result: CommandResultPayload): Promise<void> {
    await this.applyCommandResult(result);
  }

  async listRecent(limit: number): Promise<CommandLogEntry[]> {
    const result = await this.database.query<CommandLogRow>(
      `
        SELECT
          commands.command_id,
          commands.source_device_id,
          commands.target_agent_id,
          commands.action,
          commands.status,
          commands.args_json,
          commands.created_at,
          command_results.output,
          command_results.completed_at
        FROM commands
        LEFT JOIN command_results
          ON command_results.command_id = commands.command_id
        ORDER BY commands.created_at DESC
        LIMIT $1
      `,
      [limit],
    );

    return result.rows.map((row) => ({
      commandId: row.command_id,
      sourceDeviceId: row.source_device_id,
      targetAgentId: row.target_agent_id,
      action: row.action,
      status: row.status,
      createdAt: toIsoString(row.created_at),
      ...(row.args_json ? { args: row.args_json } : {}),
      ...(row.output ? { output: row.output } : {}),
      ...(row.completed_at ? { completedAt: toIsoString(row.completed_at) } : {}),
    }));
  }

  private async applyCommandResult(result: CommandResultRecord): Promise<void> {
    await this.database.transaction(async (client) => {
      const updateResult = await client.query(
        `
          UPDATE commands
          SET status = $2, updated_at = $3
          WHERE command_id = $1
        `,
        [result.commandId, result.status, result.completedAt],
      );

      if (updateResult.rowCount === 0) {
        return;
      }

      await upsertCommandResult(client, result);
    });
  }
}

async function upsertCommandResult(client: DatabaseClient, result: CommandResultRecord): Promise<void> {
  await client.query(
    `
      INSERT INTO command_results (
        command_id,
        agent_id,
        action,
        status,
        output,
        completed_at,
        created_at,
        updated_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
      ON CONFLICT (command_id)
      DO UPDATE SET
        agent_id = EXCLUDED.agent_id,
        action = EXCLUDED.action,
        status = EXCLUDED.status,
        output = EXCLUDED.output,
        completed_at = EXCLUDED.completed_at,
        updated_at = NOW()
    `,
    [
      result.commandId,
      result.agentId,
      result.action,
      result.status,
      result.output,
      result.completedAt,
    ],
  );
}

function toIsoString(value: string | Date): string {
  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}
