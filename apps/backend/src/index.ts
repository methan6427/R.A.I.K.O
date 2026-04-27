import { loadConfig } from "./config/env.js";
import { createApp } from "./server/create-app.js";

async function bootstrap(): Promise<void> {
  console.log("=== ENV DEBUG ===");
  console.log("RAIKO_AUTH_TOKEN =", process.env.RAIKO_AUTH_TOKEN);
  console.log("NODE_ENV =", process.env.NODE_ENV);
  console.log("=================");

  const config = loadConfig();
  const { app, logger, attachGateway } = await createApp(config);

  attachGateway();

  await app.listen({
    host: config.host,
    port: config.port,
  });

  logger.info("Backend started", {
    host: config.host,
    port: config.port,
    wsPath: "/ws",
  });
}


bootstrap().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});