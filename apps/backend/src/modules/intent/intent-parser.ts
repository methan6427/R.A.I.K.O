export interface ParseIntentRequest {
  text: string;
  agents: string[];
  userName: string | undefined;
}

export interface ParseIntentResponse {
  command: string;
  targetAgent: string;
  confidence: number;
}

const COMMAND_PATTERNS: Record<
  string,
  {
    keywords: string[];
    aliases?: string[];
  }
> = {
  lock: {
    keywords: ["lock"],
    aliases: ["secure", "locked"],
  },
  sleep: {
    keywords: ["sleep", "hibernate"],
    aliases: ["nap", "sleepy"],
  },
  restart: {
    keywords: ["restart", "reboot"],
    aliases: ["boot"],
  },
  shutdown: {
    keywords: ["shutdown", "power off", "turn off"],
    aliases: ["shut down", "power down"],
  },
  wake_up: {
    keywords: ["wake", "wake up", "power on", "turn on"],
    aliases: ["wake on lan", "wol"],
  },
  open_app: {
    keywords: ["open", "launch", "run", "start"],
  },
  open_remote_desktop: {
    keywords: ["remote desktop", "anydesk", "remote access"],
    aliases: ["rdp"],
  },
  set_name: {
    keywords: ["name is", "call me", "i'm", "im"],
    aliases: ["my name"],
  },
};

export class IntentParser {
  parse(request: ParseIntentRequest): ParseIntentResponse {
    const text = request.text.toLowerCase().trim();
    const agents = request.agents.map((a) => a.toLowerCase());

    // Check for set_name command
    if (this._isSetNameCommand(text)) {
      const extractedName = this._extractNameFromSetNameCommand(text);
      return {
        command: "set_name",
        targetAgent: extractedName,
        confidence: 0.9,
      };
    }

    // Find which command is being requested
    let detectedCommand = "ask_clarification";
    let commandConfidence = 0.3;

    for (const [command, pattern] of Object.entries(COMMAND_PATTERNS)) {
      if (this._matchesPattern(text, pattern)) {
        detectedCommand = command;
        commandConfidence = 0.85;
        break;
      }
    }

    // Find target agent
    let targetAgent = "all";
    let targetConfidence = 0.8;

    const foundAgent = agents.find(
      (agent) => text.includes(agent) || this._fuzzyMatch(text, agent),
    );
    if (foundAgent) {
      targetAgent = foundAgent;
      targetConfidence = 0.95;
    } else if (
      text.includes("all") ||
      text.includes("everything") ||
      text.includes("everywhere")
    ) {
      targetAgent = "all";
    }

    // Confidence is the minimum of command and target confidence
    const confidence = Math.min(commandConfidence, targetConfidence);

    return {
      command: detectedCommand,
      targetAgent: targetAgent,
      confidence: confidence,
    };
  }

  private _matchesPattern(
    text: string,
    pattern: { keywords: string[]; aliases?: string[] },
  ): boolean {
    const allKeywords = [...pattern.keywords, ...(pattern.aliases ?? [])];
    return allKeywords.some((keyword) => text.includes(keyword));
  }

  private _isSetNameCommand(text: string): boolean {
    const setNamePattern = COMMAND_PATTERNS.set_name;
    if (!setNamePattern) return false;
    return setNamePattern.keywords.some(
      (keyword) => text.includes(keyword),
    );
  }

  private _extractNameFromSetNameCommand(text: string): string {
    // Patterns: "my name is adam", "call me adam", "i'm adam", "im adam"
    const patterns = [
      /name is (.+?)(?:\.|$)/i,
      /call me (.+?)(?:\.|$)/i,
      /i'?m (.+?)(?:\.|$)/i,
    ];

    for (const pattern of patterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        return match[1].trim();
      }
    }

    return "device";
  }

  private _fuzzyMatch(text: string, agent: string): boolean {
    // Simple fuzzy match: agent name appears as a word or phrase
    const words = text.split(/\s+/);
    return words.some((word) => word.startsWith(agent.substring(0, 3)));
  }
}
