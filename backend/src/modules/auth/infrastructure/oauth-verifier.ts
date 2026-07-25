import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';

export interface OAuthProfile {
  providerId: string;
  email: string;
  emailVerified: boolean;
}

/**
 * Verifies OAuth ID tokens server-side. Google is fully implemented via
 * google-auth-library; Apple verification is stubbed with the same contract
 * (verify the JWT against Apple's public keys / audience) for a later sprint.
 */
@Injectable()
export class OAuthVerifier {
  private readonly logger = new Logger(OAuthVerifier.name);
  private readonly google: OAuth2Client;

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

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async verifyApple(_idToken: string): Promise<OAuthProfile> {
    // Sprint: verify Apple identity token signature against
    // https://appleid.apple.com/auth/keys, check iss/aud/exp, extract sub/email.
    throw new UnauthorizedException('Apple sign-in not yet configured');
  }
}
