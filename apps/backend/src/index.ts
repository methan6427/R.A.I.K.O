import { loadConfig } from "./config/env.js";
import { createApp } from "./server/create-app.js";

async function bootstrap(): Promise<void> {
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
