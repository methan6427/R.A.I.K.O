import { ActivityModule } from "../modules/activity/activity.module.js";
import { AuthModule } from "../modules/auth/auth.module.js";
import { AutomationModule } from "../modules/automation/automation.module.js";
import { CommandDispatcher } from "../modules/commands/command-dispatcher.js";
import { CommandsModule } from "../modules/commands/commands.module.js";
import { DeviceRegistry } from "../modules/devices/device-registry.js";
import { DevicesModule } from "../modules/devices/devices.module.js";

export class ModuleContainer {
  readonly auth = new AuthModule();
  readonly activity = new ActivityModule();
  readonly registry = new DeviceRegistry();
  readonly devices = new DevicesModule(this.registry);
  readonly commands = new CommandsModule(new CommandDispatcher(this.registry, this.activity));
  readonly automation = new AutomationModule();
}