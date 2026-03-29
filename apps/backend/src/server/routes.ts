import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";
import type { CommandSendPayload } from "@raiko/shared-types";
import type { ModuleContainer } from "./module-container.js";

export async function registerRoutes(app: FastifyInstance, modules: ModuleContainer): Promise<void> {
  app.get("/health", async () => ({
    status: "ok",
    uptime: process.uptime(),
    authEnabled: modules.auth.isEnabled,
  }));

  app.get("/api/overview", async (request, reply) => {
    if (!ensureAuthorized(modules, request, reply)) {
      return;
    }

    const [devices, agents, activity, commands] = await Promise.all([
      modules.devices.listDevices(),
      modules.devices.listAgents(),
      modules.activity.list(),
      modules.commands.list(),
    ]);

    return {
      devices,
      agents,
      activity,
      commands,
      automation: modules.automation.listRules(),
    };
  });

  app.get("/api/devices", async (request, reply) => {
    if (!ensureAuthorized(modules, request, reply)) {
      return;
    }

    return {
      devices: await modules.devices.listDevices(),
    };
  });

  app.get("/api/agents", async (request, reply) => {
    if (!ensureAuthorized(modules, request, reply)) {
      return;
    }

    return {
      agents: await modules.devices.listAgents(),
    };
  });

  app.get("/api/activity", async (request, reply) => {
    if (!ensureAuthorized(modules, request, reply)) {
      return;
    }

    return {
      activity: await modules.activity.list(),
    };
  });

  app.get("/api/commands", async (request, reply) => {
    if (!ensureAuthorized(modules, request, reply)) {
      return;
    }

    return {
      commands: await modules.commands.list(),
    };
  });

  app.post<{ Body: CommandSendPayload }>("/api/commands", async (request, reply) => {
    if (!ensureAuthorized(modules, request, reply)) {
      return;
    }

    const result = await modules.commands.dispatch(request.body);
    reply.code(result.ok ? 202 : 409);

    return {
      status: result.ok ? "accepted" : "rejected",
      message: result.message,
    };
  });
}

function ensureAuthorized(
  modules: ModuleContainer,
  request: FastifyRequest,
  reply: FastifyReply,
): boolean {
  const token = request.headers["x-raiko-token"];
  if (modules.auth.validateToken(token)) {
    return true;
  }

  reply.code(401).send({
    error: "Unauthorized",
  });

  return false;
}
