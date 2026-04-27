import path from "node:path";
import { fileURLToPath } from "node:url";
import { config as loadDotenv } from "dotenv";
import type { LogLevel } from "../core/logger.js";

export type BackendEnvironment = "development" | "test" | "production";
export type DatabaseSslMode = "disable" | "require";

export interface BackendConfig {
  environment: BackendEnvironment;
  host: string;
  port: number;
  authToken?: string;
  activityLimit: number;
  commandLimit: number;
  logLevel: LogLevel;
  runMigrations: boolean;
  database: {
    url: string;
    sslMode: DatabaseSslMode;
  };
  bootstrapUser: {
    id: string;
    email: string;
    displayName: string;
  };
  tts: {
    piperPath: string;
    voicesDir: string;
  };
}

let dotenvLoaded = false;

function parsePositiveInt(value: string | undefined, fallback: number): number {
  const parsed = Number(value);

  if (!Number.isInteger(parsed) || parsed <= 0) {
    return fallback;
  }

  return parsed;
}

function parseBoolean(value: string | undefined, fallback: boolean): boolean {
  if (!value) {
    return fallback;
  }

  return value === "1" || value.toLowerCase() === "true";
}

function parseEnvironment(value: string | undefined): BackendEnvironment {
  if (value === "production" || value === "test") {
    return value;
  }

  return "development";
}

function parseDatabaseSslMode(value: string | undefined): DatabaseSslMode {
  if (value === "require") {
    return "require";
  }

  return "disable";
}

function parseLogLevel(value: string | undefined, environment: BackendEnvironment): LogLevel {
  const fallback: LogLevel = environment === "production" ? "info" : "debug";

  if (!value) {
    return fallback;
  }

  if (value === "debug" || value === "info" || value === "warn" || value === "error") {
    return value;
  }

  return fallback;
}

function readRequired(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

function readOptional(value: string | undefined): string | undefined {
  const trimmed = value?.trim();
  return trimmed ? trimmed : undefined;
}

function ensureDotenvLoaded(): void {
  if (dotenvLoaded) {
    return;
  }

  const currentFilePath = fileURLToPath(import.meta.url);
  const appRoot = path.resolve(path.dirname(currentFilePath), "..", "..");
  const repoRoot = path.resolve(appRoot, "..", "..");

  loadDotenv({
    path: path.join(appRoot, ".env"),
    override: false,
  });
  loadDotenv({
    path: path.join(repoRoot, ".env"),
    override: false,
  });

  dotenvLoaded = true;
}

export function loadConfig(): BackendConfig {
  ensureDotenvLoaded();

  const environment = parseEnvironment(process.env.NODE_ENV);
  const authToken = process.env.NODE_ENV === "production" ? readOptional(process.env.RAIKO_AUTH_TOKEN) : undefined;

  const appRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
  const piperBinary = process.platform === "win32" ? "piper.exe" : "piper";
  const piperPath = process.env.RAIKO_PIPER_PATH ?? path.join(appRoot, "piper", piperBinary);
  const voicesDir = process.env.RAIKO_VOICES_DIR ?? path.join(appRoot, "piper", "voices");

  return {
    environment,
    host: process.env.RAIKO_HOST ?? "0.0.0.0",
    port: parsePositiveInt(process.env.RAIKO_PORT, 8080),
    activityLimit: parsePositiveInt(process.env.RAIKO_ACTIVITY_LIMIT, 200),
    commandLimit: parsePositiveInt(process.env.RAIKO_COMMAND_LIMIT, 200),
    logLevel: parseLogLevel(process.env.RAIKO_LOG_LEVEL, environment),
    runMigrations: parseBoolean(process.env.RAIKO_RUN_MIGRATIONS, false),
    database: {
      url: readRequired("RAIKO_DATABASE_URL"),
      sslMode: parseDatabaseSslMode(process.env.RAIKO_DATABASE_SSL_MODE),
    },
    bootstrapUser: {
      id: process.env.RAIKO_BOOTSTRAP_USER_ID ?? "operator-admin",
      email: process.env.RAIKO_BOOTSTRAP_USER_EMAIL ?? "admin@raiko.local",
      displayName: process.env.RAIKO_BOOTSTRAP_USER_DISPLAY_NAME ?? "R.A.I.K.O Operator",
    },
    tts: {
      piperPath,
      voicesDir,
    },
    ...(authToken ? { authToken } : {}),
  };
}
