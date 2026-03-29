export class AuthModule {
  constructor(private readonly expectedToken?: string) {}

  validateToken(token?: string | string[]): boolean {
    if (!this.expectedToken) {
      return true;
    }

    if (Array.isArray(token)) {
      return token.includes(this.expectedToken);
    }

    return token === this.expectedToken;
  }

  get isEnabled(): boolean {
    return Boolean(this.expectedToken);
  }
}
