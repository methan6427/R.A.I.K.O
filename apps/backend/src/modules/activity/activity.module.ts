import { Logger } from "../../core/logger.js";

export interface ActivityEntry {
  type: string;
  actorId: string;
  detail: string;
  createdAt: string;
}

export class ActivityModule {
  private readonly logger = new Logger("activity");
  private readonly entries: ActivityEntry[] = [];

  track(type: string, actorId: string, detail: string): ActivityEntry {
    const entry: ActivityEntry = {
      type,
      actorId,
      detail,
      createdAt: new Date().toISOString(),
    };

    this.entries.unshift(entry);
    this.logger.info("Activity recorded", { ...entry });
    return entry;
  }

  list(): ActivityEntry[] {
    return [...this.entries];
  }
}