import { loadConfig } from "../config/env.js";
import { createLogger } from "../core/logger.js";
import { createPostgresDatabase } from "./database.js";

async function runMigrations(): Promise<void> {
  const config = loadConfig();
  const logger = createLogger("backend", config.logLevel);
  const database = createPostgresDatabase(config.database, logger);

  try {
    await database.assertConnectivity();
    const appliedMigrations = await database.migrate();

    logger.info("Database migration command completed", {
      appliedCount: appliedMigrations.length,
      migrations: appliedMigrations,
    });
  } finally {
    await database.close();
  }
}

runMigrations().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
