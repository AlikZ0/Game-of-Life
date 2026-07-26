import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import {
  createRemoteJWKSet,
  JWTPayload,
  jwtVerify,
  type JWTVerifyGetKey,
} from 'jose';

export interface OAuthProfile {
  providerId: string;
  email: string;
  emailVerified: boolean;
}

const APPLE_ISSUER = 'https://appleid.apple.com';
const APPLE_JWKS_URL = new URL('https://appleid.apple.com/auth/keys');

/**
 * Verifies OAuth ID tokens server-side. Google uses google-auth-library; Apple
 * verifies the identity token's RS256 signature against Apple's published JWKS
 * (cached by `jose`), and checks issuer / audience / expiry.
 */
@Injectable()
export class OAuthVerifier {
  private readonly logger = new Logger(OAuthVerifier.name);
  private readonly google: OAuth2Client;
  /** Remote JWK set for Apple; `jose` caches keys and refreshes on rotation. */
  private readonly appleJwks: JWTVerifyGetKey =
    createRemoteJWKSet(APPLE_JWKS_URL);

  constructor(private readonly config: ConfigService) {
    this.google = new OAuth2Client(config.get<string>('oauth.googleClientId'));
  }

  async verifyGoogle(idToken: string): Promise<OAuthProfile> {
    try {
      const ticket = await this.google.verifyIdToken({
        idToken,
        audience: this.config.get<string>('oauth.googleClientId'),
      });
      const payload = ticket.getPayload();
      if (!payload?.sub || !payload.email) {
        throw new Error('Incomplete Google profile');
      }
      return {
        providerId: payload.sub,
        email: payload.email,
        emailVerified: Boolean(payload.email_verified),
      };
    } catch (err) {
      this.logger.warn(`Google verification failed: ${(err as Error).message}`);
      throw new UnauthorizedException('Invalid Google credential');
    }
  }

  async verifyApple(idToken: string): Promise<OAuthProfile> {
    const audience = this.config.get<string>('oauth.appleClientId');
    if (!audience) {
      throw new UnauthorizedException('Apple sign-in is not configured');
    }
    try {
      const { payload } = await jwtVerify(idToken, this.appleJwks, {
        issuer: APPLE_ISSUER,
        audience,
      });
      if (!payload.sub) throw new Error('Missing subject (sub) claim');
      return {
        providerId: payload.sub,
        // Apple only returns `email` on the first authorization; on subsequent
        // logins the user is matched by (provider, providerId) instead.
        email: typeof payload.email === 'string' ? payload.email : '',
        emailVerified: this.appleEmailVerified(payload),
      };
    } catch (err) {
      this.logger.warn(`Apple verification failed: ${(err as Error).message}`);
      throw new UnauthorizedException('Invalid Apple credential');
    }
  }

  /** Apple encodes `email_verified` as the string "true" (or a boolean). */
  private appleEmailVerified(payload: JWTPayload): boolean {
    const v = (payload as Record<string, unknown>).email_verified;
    return v === true || v === 'true';
  }
}
