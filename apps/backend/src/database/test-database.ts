import { newDb } from "pg-mem";
import { Logger } from "../core/logger.js";
import { createPostgresDatabase, type PostgresDatabase } from "./database.js";

export function createInMemoryDatabase(logger: Logger): PostgresDatabase {
  const database = newDb({
    autoCreateForeignKeyIndices: true,
    noAstCoverageCheck: true,
  });

  const adapter = database.adapters.createPg();
  const pool = new adapter.Pool();

  return createPostgresDatabase(
    {
      url: "postgres://raiko:test@localhost:5432/raiko_test",
      sslMode: "disable",
    },
    logger,
    { pool },
  );
}
