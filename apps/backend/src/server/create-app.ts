import Fastify from "fastify";
import rateLimit from "@fastify/rate-limit";
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
    // Honour X-Forwarded-For so per-IP rate limits + access logs see the real client
    // behind nginx + Cloudflare. Safe because port 8080 is only reachable via the proxy.
    trustProxy: true,
  });

  await app.register(rateLimit, {
    global: true,
    max: 120,
    timeWindow: "1 minute",
    // Health checks (Docker, Coolify, uptime monitors) and the WebSocket upgrade
    // path must never be limited.
    allowList: (request) => request.url === "/health" || request.url.startsWith("/ws"),
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
