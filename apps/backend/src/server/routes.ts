import type { FastifyInstance } from "fastify";
import type { ModuleContainer } from "./module-container.js";

export async function registerRoutes(app: FastifyInstance, modules: ModuleContainer): Promise<void> {
  app.get("/health", async () => ({
    status: "ok",
    uptime: process.uptime(),
  }));

  app.get("/api/overview", async () => ({
    devices: modules.devices.listDevices(),
    agents: modules.devices.listAgents(),
    activity: modules.activity.list(),
    automation: modules.automation.listRules(),
  }));
}