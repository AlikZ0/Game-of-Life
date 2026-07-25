import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { createHash, randomBytes } from 'crypto';

export interface AccessTokenPayload {
  sub: string; // userId
  email: string;
  characterId?: string;
}

/**
 * Issues short-lived signed access tokens and opaque, hashed refresh tokens.
 * Refresh tokens are random 256-bit strings; only their SHA-256 hash is stored,
 * so a database leak never exposes usable tokens (rotation on every refresh).
 */
@Injectable()
export class TokenService {
  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async signAccessToken(payload: AccessTokenPayload): Promise<string> {
    return this.jwt.signAsync(payload, {
      secret: this.config.get<string>('jwt.accessSecret'),
      expiresIn: this.config.get<number>('jwt.accessTtl'),
    });
  }

  /** Generates a raw refresh token (returned to client) + its stored hash. */
  generateRefreshToken(): { raw: string; hash: string; expiresAt: Date } {
    const raw = randomBytes(48).toString('base64url');
    const ttl = this.config.get<number>('jwt.refreshTtl', 2592000);
    return {
      raw,
      hash: this.hashRefresh(raw),
      expiresAt: new Date(Date.now() + ttl * 1000),
    };
  }

  hashRefresh(raw: string): string {
    return createHash('sha256').update(raw).digest('hex');
  }

  get accessTtl(): number {
    return this.config.get<number>('jwt.accessTtl', 900);
  }
}
