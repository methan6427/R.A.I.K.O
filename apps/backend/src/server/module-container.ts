import type { BackendConfig } from "../config/env.js";
import type { PostgresDatabase } from "../database/database.js";
import type { Logger } from "../core/logger.js";
import { ActivityModule } from "../modules/activity/activity.module.js";
import { PostgresActivityRepository } from "../modules/activity/activity.repository.js";
import { AuthModule } from "../modules/auth/auth.module.js";
import { AutomationModule } from "../modules/automation/automation.module.js";
import { CommandDispatcher } from "../modules/commands/command-dispatcher.js";
import { CommandsModule } from "../modules/commands/commands.module.js";
import { PostgresCommandsRepository } from "../modules/commands/commands.repository.js";
import { DeviceRegistry } from "../modules/devices/device-registry.js";
import { DevicesModule } from "../modules/devices/devices.module.js";
import { PostgresDevicesRepository } from "../modules/devices/devices.repository.js";
import { PostgresSettingsRepository } from "../modules/settings/settings.repository.js";
import { SettingsModule } from "../modules/settings/settings.module.js";
import { PostgresUserRepository } from "../modules/users/user.repository.js";
import { UsersModule } from "../modules/users/users.module.js";
import { VoiceModule } from "../modules/voice/voice.module.js";
import { IntentParser } from "../modules/intent/intent-parser.js";

export class ModuleContainer {
  readonly auth: AuthModule;
  readonly activity: ActivityModule;
  readonly registry: DeviceRegistry;
  readonly devices: DevicesModule;
  readonly commands: CommandsModule;
  readonly automation: AutomationModule;
  readonly settings: SettingsModule;
  readonly users: UsersModule;
  readonly voice: VoiceModule;
  readonly intent: IntentParser;

  private constructor(params: {
    auth: AuthModule;
    activity: ActivityModule;
    registry: DeviceRegistry;
    devices: DevicesModule;
    commands: CommandsModule;
    automation: AutomationModule;
    settings: SettingsModule;
    users: UsersModule;
    voice: VoiceModule;
    intent: IntentParser;
  }) {
    this.auth = params.auth;
    this.activity = params.activity;
    this.registry = params.registry;
    this.devices = params.devices;
    this.commands = params.commands;
    this.automation = params.automation;
    this.settings = params.settings;
    this.users = params.users;
    this.voice = params.voice;
    this.intent = params.intent;
  }

  static async create(
    config: BackendConfig,
    dependencies: {
      database: PostgresDatabase;
      logger: Logger;
    },
  ): Promise<ModuleContainer> {
    const auth = new AuthModule(config.authToken);
    const registry = new DeviceRegistry();
    const activity = new ActivityModule(
      new PostgresActivityRepository(dependencies.database),
      dependencies.logger.child("activity"),
      config.activityLimit,
    );
    const users = new UsersModule(
      new PostgresUserRepository(dependencies.database),
      config.bootstrapUser,
    );
    const settings = new SettingsModule(new PostgresSettingsRepository(dependencies.database));
    const devicesRepository = new PostgresDevicesRepository(dependencies.database);
    const devices = new DevicesModule(
      devicesRepository,
      registry,
      users.defaultUserId,
      dependencies.logger.child("devices"),
    );
    const commands = new CommandsModule(
      new PostgresCommandsRepository(dependencies.database),
      new CommandDispatcher(
        registry,
        dependencies.logger.child("commands"),
        devicesRepository,
      ),
      activity,
      config.commandLimit,
    );
    const automation = new AutomationModule();
    const voice = new VoiceModule(config);
    const intent = new IntentParser();

    await devices.reconcileStartupState();
    await users.ensureBootstrapUser();
    await settings.syncRuntimeSettings(config);

    return new ModuleContainer({
      auth,
      activity,
      registry,
      devices,
      commands,
      automation,
      settings,
      users,
      voice,
      intent,
    });
  }
}
