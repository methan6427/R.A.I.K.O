export class AuthModule {
  validateToken(token?: string): boolean {
    if (!token) {
      return true;
    }

    return token.length >= 8;
  }
}