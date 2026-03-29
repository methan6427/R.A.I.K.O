import { DeviceRegistry } from "./device-registry.js";

export class DevicesModule {
  constructor(private readonly registry: DeviceRegistry) {}

  listDevices() {
    return this.registry.listDevices();
  }

  listAgents() {
    return this.registry.listAgents();
  }
}