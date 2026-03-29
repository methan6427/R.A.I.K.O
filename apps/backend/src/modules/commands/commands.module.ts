import { CommandDispatcher } from "./command-dispatcher.js";

export class CommandsModule {
  constructor(private readonly dispatcher: CommandDispatcher) {}

  get commandDispatcher(): CommandDispatcher {
    return this.dispatcher;
  }
}