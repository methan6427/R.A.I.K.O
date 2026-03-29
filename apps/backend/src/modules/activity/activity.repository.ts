import type { QueryResultRow } from "pg";
import type { ActivityEntry } from "@raiko/shared-types";
import type { DatabaseClient } from "../../database/database.js";

export interface ActivityRepository {
  insert(entry: ActivityEntry): Promise<ActivityEntry>;
  listRecent(limit: number): Promise<ActivityEntry[]>;
}

interface ActivityRow extends QueryResultRow {
  actor_id: string;
  type: string;
  detail: string;
  created_at: string | Date;
}

export class PostgresActivityRepository implements ActivityRepository {
  constructor(private readonly database: DatabaseClient) {}

  async insert(entry: ActivityEntry): Promise<ActivityEntry> {
    await this.database.query(
      `
        INSERT INTO activity_logs (actor_id, type, detail, created_at)
        VALUES ($1, $2, $3, $4)
      `,
      [entry.actorId, entry.type, entry.detail, entry.createdAt],
    );

    return entry;
  }

  async listRecent(limit: number): Promise<ActivityEntry[]> {
    const result = await this.database.query<ActivityRow>(
      `
        SELECT actor_id, type, detail, created_at
        FROM activity_logs
        ORDER BY created_at DESC
        LIMIT $1
      `,
      [limit],
    );

    return result.rows.map((row) => ({
      actorId: row.actor_id,
      type: row.type,
      detail: row.detail,
      createdAt: toIsoString(row.created_at),
    }));
  }
}

function toIsoString(value: string | Date): string {
  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}
