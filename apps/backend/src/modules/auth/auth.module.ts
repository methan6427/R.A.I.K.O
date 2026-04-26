import { timingSafeEqual } from "node:crypto";

export class AuthModule {
  private readonly expectedTokenBuffer?: Buffer;

  constructor(private readonly expectedToken?: string) {
    if (expectedToken) {
      this.expectedTokenBuffer = Buffer.from(expectedToken, "utf8");
    }
  }

  validateToken(token?: string | string[]): boolean {
    if (!this.expectedTokenBuffer) {
      return true;
    }

    if (Array.isArray(token)) {
      return token.some((candidate) => this.compare(candidate));
    }

    return this.compare(token);
  }

  get isEnabled(): boolean {
    return Boolean(this.expectedTokenBuffer);
  }

  private compare(candidate: string | undefined): boolean {
    if (!candidate || !this.expectedTokenBuffer) {
      return false;
    }
    const candidateBuffer = Buffer.from(candidate, "utf8");
    if (candidateBuffer.length !== this.expectedTokenBuffer.length) {
      return false;
    }
    return timingSafeEqual(candidateBuffer, this.expectedTokenBuffer);
  }
}
