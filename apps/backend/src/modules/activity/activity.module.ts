import type { ActivityEntry } from "@raiko/shared-types";
import { Logger } from "../../core/logger.js";
import type { ActivityRepository } from "./activity.repository.js";

export class ActivityModule {
  constructor(
    private readonly repository: ActivityRepository,
    private readonly logger: Logger,
    private readonly limit = 200,
  ) {}

  async track(type: string, actorId: string, detail: string): Promise<ActivityEntry> {
    const entry: ActivityEntry = {
      type,
      actorId,
      detail,
      createdAt: new Date().toISOString(),
    };

    await this.repository.insert(entry);
    this.logger.info("Activity recorded", { ...entry });
    return entry;
  }

  async list(): Promise<ActivityEntry[]> {
    return this.repository.listRecent(this.limit);
  }
}
