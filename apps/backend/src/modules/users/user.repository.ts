import type { QueryResultRow } from "pg";
import type { DatabaseClient } from "../../database/database.js";

export interface UserRecord {
  id: string;
  email: string;
  displayName: string;
  createdAt: string;
}

export interface UserRepository {
  upsert(user: {
    id: string;
    email: string;
    displayName: string;
  }): Promise<UserRecord>;
}

interface UserRow extends QueryResultRow {
  id: string;
  email: string;
  display_name: string;
  created_at: string | Date;
}

export class PostgresUserRepository implements UserRepository {
  constructor(private readonly database: DatabaseClient) {}

  async upsert(user: {
    id: string;
    email: string;
    displayName: string;
  }): Promise<UserRecord> {
    const result = await this.database.query<UserRow>(
      `
        INSERT INTO users (id, email, display_name, updated_at)
        VALUES ($1, $2, $3, NOW())
        ON CONFLICT (id)
        DO UPDATE SET
          email = EXCLUDED.email,
          display_name = EXCLUDED.display_name,
          updated_at = NOW()
        RETURNING id, email, display_name, created_at
      `,
      [user.id, user.email, user.displayName],
    );

    return {
      id: result.rows[0]!.id,
      email: result.rows[0]!.email,
      displayName: result.rows[0]!.display_name,
      createdAt: toIsoString(result.rows[0]!.created_at),
    };
  }
}

function toIsoString(value: string | Date): string {
  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}
