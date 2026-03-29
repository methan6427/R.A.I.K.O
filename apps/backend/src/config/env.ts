export interface BackendConfig {
  host: string;
  port: number;
}

export function loadConfig(): BackendConfig {
  return {
    host: process.env.RAIKO_HOST ?? "0.0.0.0",
    port: Number(process.env.RAIKO_PORT ?? "8080"),
  };
}