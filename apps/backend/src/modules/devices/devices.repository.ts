import type { QueryResultRow } from "pg";
import {
  AgentCommand,
  type AgentSummary,
  type ConnectionStatus,
  type DeviceSummary,
} from "@raiko/shared-types";
import type { DatabaseClient } from "../../database/database.js";

export interface UpsertDeviceConnectionInput {
  id: string;
  userId?: string;
  name: string;
  platform: string;
  kind: "mobile" | "desktop";
  connectedAt: string;
  lastSeenAt: string;
}

export interface UpsertAgentConnectionInput {
  id: string;
  name: string;
  platform: string;
  supportedCommands: AgentCommand[];
  connectedAt: string;
  lastSeenAt: string;
}

export interface DevicesRepository {
  upsertDeviceConnection(input: UpsertDeviceConnectionInput): Promise<DeviceSummary>;
  upsertAgentConnection(input: UpsertAgentConnectionInput): Promise<AgentSummary>;
  reconcileStartupState(disconnectedAt: string): Promise<{
    devicesMarkedOffline: number;
    agentsMarkedOffline: number;
  }>;
  markHeartbeat(clientId: string, status: ConnectionStatus, sentAt: string): Promise<void>;
  markDeviceDisconnected(deviceId: string, disconnectedAt: string): Promise<void>;
  markAgentDisconnected(agentId: string, disconnectedAt: string): Promise<void>;
  listOnlineDevices(): Promise<DeviceSummary[]>;
  listOnlineAgents(): Promise<AgentSummary[]>;
}

interface DeviceRow extends QueryResultRow {
  id: string;
  name: string;
  platform: string;
  kind: "mobile" | "desktop";
  status: ConnectionStatus;
  connected_at: string | Date;
  last_seen_at: string | Date;
}

interface AgentRow extends QueryResultRow {
  id: string;
  name: string;
  platform: string;
  status: ConnectionStatus;
  connected_at: string | Date;
  last_seen_at: string | Date;
  supported_commands: AgentCommand[] | null;
}

export class PostgresDevicesRepository implements DevicesRepository {
  constructor(private readonly database: DatabaseClient) {}

  async reconcileStartupState(disconnectedAt: string): Promise<{
    devicesMarkedOffline: number;
    agentsMarkedOffline: number;
  }> {
    const devicesResult = await this.database.query(
      `
        UPDATE devices
        SET status = 'offline',
            disconnected_at = COALESCE(disconnected_at, $1),
            updated_at = NOW()
        WHERE status = 'online'
      `,
      [disconnectedAt],
    );
    const agentsResult = await this.database.query(
      `
        UPDATE agents
        SET status = 'offline',
            disconnected_at = COALESCE(disconnected_at, $1),
            updated_at = NOW()
        WHERE status = 'online'
      `,
      [disconnectedAt],
    );

    return {
      devicesMarkedOffline: devicesResult.rowCount ?? 0,
      agentsMarkedOffline: agentsResult.rowCount ?? 0,
    };
  }

  async upsertDeviceConnection(input: UpsertDeviceConnectionInput): Promise<DeviceSummary> {
    const result = await this.database.query<DeviceRow>(
      `
        INSERT INTO devices (
          id,
          user_id,
          name,
          platform,
          kind,
          status,
          connected_at,
          last_seen_at,
          disconnected_at,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, 'online', $6, $7, NULL, NOW())
        ON CONFLICT (id)
        DO UPDATE SET
          user_id = COALESCE(EXCLUDED.user_id, devices.user_id),
          name = EXCLUDED.name,
          platform = EXCLUDED.platform,
          kind = EXCLUDED.kind,
          status = EXCLUDED.status,
          connected_at = EXCLUDED.connected_at,
          last_seen_at = EXCLUDED.last_seen_at,
          disconnected_at = NULL,
          updated_at = NOW()
        RETURNING id, name, platform, kind, status, connected_at, last_seen_at
      `,
      [
        input.id,
        input.userId ?? null,
        input.name,
        input.platform,
        input.kind,
        input.connectedAt,
        input.lastSeenAt,
      ],
    );

    return mapDeviceRow(result.rows[0]!);
  }

  async upsertAgentConnection(input: UpsertAgentConnectionInput): Promise<AgentSummary> {
    const result = await this.database.query<AgentRow>(
      `
        INSERT INTO agents (
          id,
          name,
          platform,
          status,
          supported_commands,
          connected_at,
          last_seen_at,
          disconnected_at,
          updated_at
        )
        VALUES ($1, $2, $3, 'online', $4, $5, $6, NULL, NOW())
        ON CONFLICT (id)
        DO UPDATE SET
          name = EXCLUDED.name,
          platform = EXCLUDED.platform,
          status = EXCLUDED.status,
          supported_commands = EXCLUDED.supported_commands,
          connected_at = EXCLUDED.connected_at,
          last_seen_at = EXCLUDED.last_seen_at,
          disconnected_at = NULL,
          updated_at = NOW()
        RETURNING id, name, platform, status, connected_at, last_seen_at, supported_commands
      `,
      [
        input.id,
        input.name,
        input.platform,
        JSON.stringify(input.supportedCommands),
        input.connectedAt,
        input.lastSeenAt,
      ],
    );

    return mapAgentRow(result.rows[0]!);
  }

  async markHeartbeat(clientId: string, status: ConnectionStatus, sentAt: string): Promise<void> {
    const deviceResult = await this.database.query(
      `
        UPDATE devices
        SET status = $2, last_seen_at = $3, updated_at = NOW()
        WHERE id = $1
      `,
      [clientId, status, sentAt],
    );

    if (deviceResult.rowCount && deviceResult.rowCount > 0) {
      return;
    }

    await this.database.query(
      `
        UPDATE agents
        SET status = $2, last_seen_at = $3, updated_at = NOW()
        WHERE id = $1
      `,
      [clientId, status, sentAt],
    );
  }

  async markDeviceDisconnected(deviceId: string, disconnectedAt: string): Promise<void> {
    await this.database.query(
      `
        UPDATE devices
        SET status = 'offline',
            last_seen_at = $2,
            disconnected_at = $2,
            updated_at = NOW()
        WHERE id = $1
      `,
      [deviceId, disconnectedAt],
    );
  }

  async markAgentDisconnected(agentId: string, disconnectedAt: string): Promise<void> {
    await this.database.query(
      `
        UPDATE agents
        SET status = 'offline',
            last_seen_at = $2,
            disconnected_at = $2,
            updated_at = NOW()
        WHERE id = $1
      `,
      [agentId, disconnectedAt],
    );
  }

  async listOnlineDevices(): Promise<DeviceSummary[]> {
    const result = await this.database.query<DeviceRow>(
      `
        SELECT id, name, platform, kind, status, connected_at, last_seen_at
        FROM devices
        WHERE status = 'online'
        ORDER BY connected_at DESC
      `,
    );

    return result.rows.map(mapDeviceRow);
  }

  async listOnlineAgents(): Promise<AgentSummary[]> {
    const result = await this.database.query<AgentRow>(
      `
        SELECT id, name, platform, status, connected_at, last_seen_at, supported_commands
        FROM agents
        WHERE status = 'online'
        ORDER BY connected_at DESC
      `,
    );

    return result.rows.map(mapAgentRow);
  }
}

function mapDeviceRow(row: DeviceRow): DeviceSummary {
  return {
    id: row.id,
    name: row.name,
    platform: row.platform,
    kind: row.kind,
    status: row.status,
    connectedAt: toIsoString(row.connected_at),
    lastSeenAt: toIsoString(row.last_seen_at),
  };
}

function mapAgentRow(row: AgentRow): AgentSummary {
  return {
    id: row.id,
    name: row.name,
    platform: row.platform,
    status: row.status,
    connectedAt: toIsoString(row.connected_at),
    lastSeenAt: toIsoString(row.last_seen_at),
    supportedCommands: normalizeSupportedCommands(row.supported_commands),
  };
}

function normalizeSupportedCommands(value: AgentCommand[] | null): AgentCommand[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.filter((item): item is AgentCommand => Object.values(AgentCommand).includes(item));
}

function toIsoString(value: string | Date): string {
  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}
