export type LogLevel = "debug" | "info" | "warn" | "error";

export interface LoggerOptions {
  readonly minLevel?: LogLevel;
  readonly defaultMeta?: Record<string, unknown>;
  readonly sink?: (serializedEntry: string) => void;
}

const LOG_LEVEL_PRIORITY: Record<LogLevel, number> = {
  debug: 10,
  info: 20,
  warn: 30,
  error: 40,
};

export class Logger {
  constructor(
    private readonly scope: string,
    private readonly options: LoggerOptions = {},
  ) {}

  child(scope: string, defaultMeta?: Record<string, unknown>): Logger {
    const childOptions: LoggerOptions = {
      ...(this.options.minLevel ? { minLevel: this.options.minLevel } : {}),
      ...(this.options.sink ? { sink: this.options.sink } : {}),
      defaultMeta: {
        ...(this.options.defaultMeta ?? {}),
        ...(defaultMeta ?? {}),
      },
    };

    return new Logger(`${this.scope}:${scope}`, childOptions);
  }

  debug(message: string, meta?: Record<string, unknown>): void {
    this.log("debug", message, meta);
  }

  info(message: string, meta?: Record<string, unknown>): void {
    this.log("info", message, meta);
  }

  warn(message: string, meta?: Record<string, unknown>): void {
    this.log("warn", message, meta);
  }

  error(message: string, meta?: Record<string, unknown>): void {
    this.log("error", message, meta);
  }

  private log(level: LogLevel, message: string, meta?: Record<string, unknown>): void {
    const configuredLevel = this.options.minLevel ?? "info";
    if (LOG_LEVEL_PRIORITY[level] < LOG_LEVEL_PRIORITY[configuredLevel]) {
      return;
    }

    const resolvedMeta = this.resolveMeta(meta);
    const entry = {
      timestamp: new Date().toISOString(),
      level,
      scope: this.scope,
      message,
      ...(resolvedMeta ? { meta: resolvedMeta } : {}),
    };

    const serializedEntry = JSON.stringify(entry);
    if (this.options.sink) {
      this.options.sink(serializedEntry);
      return;
    }

    if (level === "error") {
      console.error(serializedEntry);
      return;
    }

    if (level === "warn") {
      console.warn(serializedEntry);
      return;
    }

    console.log(serializedEntry);
  }

  private resolveMeta(meta?: Record<string, unknown>): Record<string, unknown> | undefined {
    const mergedMeta = {
      ...(this.options.defaultMeta ?? {}),
      ...(meta ?? {}),
    };

    if (Object.keys(mergedMeta).length === 0) {
      return undefined;
    }

    return mergedMeta;
  }
}

export function createLogger(scope: string, minLevel: LogLevel): Logger {
  return new Logger(scope, { minLevel });
}
