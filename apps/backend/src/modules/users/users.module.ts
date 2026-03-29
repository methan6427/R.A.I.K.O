import type { BackendConfig } from "../../config/env.js";
import type { UserRepository } from "./user.repository.js";

export class UsersModule {
  constructor(
    private readonly repository: UserRepository,
    private readonly bootstrapUser: BackendConfig["bootstrapUser"],
  ) {}

  async ensureBootstrapUser(): Promise<void> {
    await this.repository.upsert(this.bootstrapUser);
  }

  get defaultUserId(): string {
    return this.bootstrapUser.id;
  }
}
