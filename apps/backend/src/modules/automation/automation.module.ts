export interface AutomationRule {
  id: string;
  name: string;
  trigger: string;
  action: string;
}

export class AutomationModule {
  private readonly rules: AutomationRule[] = [];

  listRules(): AutomationRule[] {
    return [...this.rules];
  }
}