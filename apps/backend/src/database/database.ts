import fs from "node:fs/promises";
import path from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import { Pool, type PoolClient, type QueryResult, type QueryResultRow } from "pg";
import type { DatabaseSslMode } from "../config/env.js";
import { Logger } from "../core/logger.js";

export interface DatabaseClient {
  query<TRow extends QueryResultRow>(
    queryText: string,
    values?: readonly unknown[],
  ): Promise<QueryResult<TRow>>;
}

export interface TransactionalDatabaseClient extends DatabaseClient {
  transaction<TResult>(callback: (client: DatabaseClient) => Promise<TResult>): Promise<TResult>;
}

export interface DatabasePoolLike extends DatabaseClient {
  connect(): Promise<PoolClientLike>;
  end(): Promise<void>;
}

export interface PoolClientLike extends DatabaseClient {
  release(): void;
}

export interface PostgresDatabaseOptions {
  readonly pool?: DatabasePoolLike;
  readonly migrationsDir?: string;
}

interface MigrationRecordRow extends QueryResultRow {
  filename: string;
  checksum: string;
}

interface MigrationDefinition {
  readonly filename: string;
  readonly checksum: string;
  readonly sql: string;
}

export class PostgresDatabase implements TransactionalDatabaseClient {
  private readonly migrationsDir: string;
  private closed = false;

  constructor(
    private readonly pool: DatabasePoolLike,
    private readonly logger: Logger,
    private readonly ownsPool: boolean,
    migrationsDir?: string,
  ) {
    this.migrationsDir = migrationsDir ?? resolveDefaultMigrationsDir();
  }

  async query<TRow extends QueryResultRow>(
    queryText: string,
    values: readonly unknown[] = [],
  ): Promise<QueryResult<TRow>> {
    return this.pool.query<TRow>(queryText, values);
  }

  async transaction<TResult>(callback: (client: DatabaseClient) => Promise<TResult>): Promise<TResult> {
    const client = await this.pool.connect();

    try {
      await client.query("BEGIN");
      const result = await callback(client);
      await client.query("COMMIT");
      return result;
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }

  async assertConnectivity(): Promise<void> {
    await this.query("SELECT 1 AS connected");
    this.logger.info("Database connectivity check passed");
  }

  async listPendingMigrations(): Promise<string[]> {
    const pendingMigrations = await this.resolvePendingMigrations();
    return pendingMigrations.map((migration) => migration.filename);
  }

  async migrate(): Promise<string[]> {
    const pendingMigrations = await this.resolvePendingMigrations();

    for (const migration of pendingMigrations) {
      await this.transaction(async (client) => {
        await client.query(migration.sql);
        await client.query(
          `
            INSERT INTO schema_migrations (filename, checksum, applied_at)
            VALUES ($1, $2, NOW())
          `,
          [migration.filename, migration.checksum],
        );
      });

      this.logger.info("Applied database migration", {
        migration: migration.filename,
      });
    }

    if (pendingMigrations.length === 0) {
      this.logger.info("Database schema is current");
    }

    return pendingMigrations.map((migration) => migration.filename);
  }

  async ensureReady(options: { runMigrations: boolean }): Promise<void> {
    await this.assertConnectivity();

    if (options.runMigrations) {
      await this.migrate();
      return;
    }

    const pendingMigrations = await this.listPendingMigrations();
    if (pendingMigrations.length > 0) {
      throw new Error(
        `Pending database migrations detected: ${pendingMigrations.join(", ")}. ` +
          "Run `npm run migrate --workspace @raiko/backend` or set RAIKO_RUN_MIGRATIONS=true.",
      );
    }
  }

  async close(): Promise<void> {
    if (this.closed) {
      return;
    }

    this.closed = true;
    await this.pool.end();
  }

  private async resolvePendingMigrations(): Promise<MigrationDefinition[]> {
    await this.ensureMigrationTable();

    const migrationFiles = await this.loadMigrationFiles();
    const appliedMigrations = await this.loadAppliedMigrations();

    return migrationFiles.filter((migration) => {
      const appliedMigration = appliedMigrations.get(migration.filename);
      if (!appliedMigration) {
        return true;
      }

      if (appliedMigration !== migration.checksum) {
        throw new Error(
          `Checksum mismatch for applied migration ${migration.filename}. ` +
            "Refuse to continue because the migration history is no longer trustworthy.",
        );
      }

      return false;
    });
  }

  private async ensureMigrationTable(): Promise<void> {
    await this.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        filename TEXT PRIMARY KEY,
        checksum TEXT NOT NULL,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);
  }

  private async loadAppliedMigrations(): Promise<Map<string, string>> {
    const result = await this.query<MigrationRecordRow>(
      `
        SELECT filename, checksum
        FROM schema_migrations
      `,
    );

    return new Map(result.rows.map((row) => [row.filename, row.checksum]));
  }

  private async loadMigrationFiles(): Promise<MigrationDefinition[]> {
    const directoryEntries = await fs.readdir(this.migrationsDir, {
      withFileTypes: true,
    });

    const migrationFiles = directoryEntries
      .filter((entry) => entry.isFile() && /^\d+_.+\.sql$/.test(entry.name))
      .map((entry) => entry.name)
      .sort((left, right) => left.localeCompare(right));

    return Promise.all(
      migrationFiles.map(async (filename) => {
        const absolutePath = path.join(this.migrationsDir, filename);
        const sql = await fs.readFile(absolutePath, "utf8");

        return {
          filename,
          sql,
          checksum: createHash("sha256").update(sql).digest("hex"),
        } satisfies MigrationDefinition;
      }),
    );
  }
}

export function createPostgresDatabase(
  config: {
    url: string;
    sslMode: DatabaseSslMode;
  },
  logger: Logger,
  options: PostgresDatabaseOptions = {},
): PostgresDatabase {
  const pool =
    options.pool ??
    new Pool({
      connectionString: config.url,
      ssl:
        config.sslMode === "require"
          ? {
              rejectUnauthorized: true,
            }
          : undefined,
    });

  return new PostgresDatabase(
    pool,
    logger.child("database"),
    options.pool === undefined,
    options.migrationsDir,
  );
}

function resolveDefaultMigrationsDir(): string {
  const currentFilePath = fileURLToPath(import.meta.url);
  return path.resolve(path.dirname(currentFilePath), "..", "..", "migrations");
}
