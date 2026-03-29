import type { TransactionalDatabaseClient } from "../../database/database.js";

export interface SettingRecord {
  key: string;
  value: unknown;
}

export interface SettingsRepository {
  upsertMany(settings: readonly SettingRecord[]): Promise<void>;
}

export class PostgresSettingsRepository implements SettingsRepository {
  constructor(private readonly database: TransactionalDatabaseClient) {}

  async upsertMany(settings: readonly SettingRecord[]): Promise<void> {
    if (settings.length === 0) {
      return;
    }

    await this.database.transaction(async (client) => {
      for (const setting of settings) {
        await client.query(
          `
            INSERT INTO app_settings (key, value, updated_at)
            VALUES ($1, $2, NOW())
            ON CONFLICT (key)
            DO UPDATE SET
              value = EXCLUDED.value,
              updated_at = NOW()
          `,
          [setting.key, JSON.stringify(setting.value)],
        );
      }
    });
  }
}
