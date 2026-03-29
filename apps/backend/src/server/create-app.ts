import Fastify from "fastify";
import { Logger } from "../core/logger.js";
import type { BackendConfig } from "../config/env.js";
import { createLogger } from "../core/logger.js";
import { createPostgresDatabase, type PostgresDatabase } from "../database/database.js";
import { registerRoutes } from "./routes.js";
import { attachWebSocketGateway } from "./websocket-gateway.js";
import { ModuleContainer } from "./module-container.js";

export async function createApp(
  config: BackendConfig,
  dependencies: {
    logger?: Logger;
    database?: PostgresDatabase;
  } = {},
) {
  const logger = dependencies.logger ?? createLogger("backend", config.logLevel);
  const database = dependencies.database ?? createPostgresDatabase(config.database, logger);
  const app = Fastify({
    logger: false,
  });

  await database.ensureReady({
    runMigrations: config.runMigrations,
  });
  const modules = await ModuleContainer.create(config, { database, logger });
  await registerRoutes(app, modules);

  if (!dependencies.database) {
    app.addHook("onClose", async () => {
      await database.close();
    });
  }

  return {
    app,
    modules,
    logger,
    database,
    attachGateway() {
      attachWebSocketGateway(app.server, modules, logger.child("ws-gateway"));
    },
  };
}
