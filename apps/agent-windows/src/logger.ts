export class AgentLogger {
  info(message: string, meta?: Record<string, unknown>): void {
    const payload = meta ? ` ${JSON.stringify(meta)}` : "";
    console.log(`[agent] ${message}${payload}`);
  }

  error(message: string, meta?: Record<string, unknown>): void {
    const payload = meta ? ` ${JSON.stringify(meta)}` : "";
    console.error(`[agent] ${message}${payload}`);
  }
}