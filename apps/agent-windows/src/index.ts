import "dotenv/config";
import { loadConfig } from "./config.js";
import { AgentClient } from "./agent/agent-client.js";
import { AgentLogger } from "./logger.js";

const logger = new AgentLogger();
const config = loadConfig();

logger.info("Starting Windows agent", {
  agentId: config.agentId,
  backendUrl: config.backendUrl,
  dryRun: config.dryRun,
});

new AgentClient(config, logger).connect();
