import type { BackendConfig } from "../../config/env.js";
import type { SettingsRepository } from "./settings.repository.js";

export class SettingsModule {
  constructor(private readonly repository: SettingsRepository) {}

  async syncRuntimeSettings(config: BackendConfig): Promise<void> {
    await this.repository.upsertMany([
      {
        key: "runtime.environment",
        value: config.environment,
      },
      {
        key: "runtime.authEnabled",
        value: Boolean(config.authToken),
      },
      {
        key: "runtime.activityLimit",
        value: config.activityLimit,
      },
      {
        key: "runtime.commandLimit",
        value: config.commandLimit,
      },
    ]);
  }
}
