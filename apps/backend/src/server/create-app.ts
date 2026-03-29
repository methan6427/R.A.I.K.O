import Fastify from "fastify";
import { Logger } from "../core/logger.js";
import { registerRoutes } from "./routes.js";
import { attachWebSocketGateway } from "./websocket-gateway.js";
import { ModuleContainer } from "./module-container.js";

export async function createApp() {
  const logger = new Logger("backend");
  const modules = new ModuleContainer();
  const app = Fastify({
    logger: false,
  });

  await registerRoutes(app, modules);

  return {
    app,
    modules,
    logger,
    attachGateway() {
      attachWebSocketGateway(app.server, modules);
    },
  };
}