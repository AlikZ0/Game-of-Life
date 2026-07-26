import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface FcmMessage {
  title: string;
  body: string;
  data?: Record<string, string>;
}

// Minimal shape of the bits of firebase-admin messaging we use, so the rest of
// the code is typed without taking a hard compile-time dependency on the SDK.
interface Messaging {
  sendEachForMulticast(message: {
    tokens: string[];
    notification: { title: string; body: string };
    data?: Record<string, string>;
  }): Promise<{
    responses: Array<{ success: boolean; error?: { code?: string } }>;
  }>;
}

// FCM error codes that mean the token is permanently dead and should be pruned.
const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/**
 * Thin wrapper over Firebase Admin messaging. The SDK is an optional dependency:
 * it is `require`d lazily only when Firebase credentials are configured, so
 * local/CI environments without `firebase-admin` installed (or without creds)
 * simply report `enabled === false` and never touch the module.
 */
@Injectable()
export class FcmSender {
  private readonly logger = new Logger(FcmSender.name);
  // undefined = not resolved yet, null = resolved but unavailable.
  private messaging?: Messaging | null;

  constructor(private readonly config: ConfigService) {}

  /** True when Firebase credentials are present in the environment. */
  get enabled(): boolean {
    return !!this.config.get<string>('firebase.projectId');
  }

  /**
   * Push a notification to many device tokens at once. Returns the tokens FCM
   * reported as permanently invalid, so the caller can prune them. A no-op
   * (empty result) when Firebase is unavailable.
   */
  async sendMulticast(
    tokens: string[],
    message: FcmMessage,
  ): Promise<string[]> {
    if (tokens.length === 0) return [];
    const messaging = this.resolve();
    if (!messaging) return [];

    const res = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: message.title, body: message.body },
      data: message.data,
    });

    const dead: string[] = [];
    res.responses.forEach((r, i) => {
      if (!r.success && r.error?.code && DEAD_TOKEN_CODES.has(r.error.code)) {
        dead.push(tokens[i]);
      }
    });
    return dead;
  }

  /** Lazily initialise (and cache) the Firebase Admin messaging client. */
  private resolve(): Messaging | null {
    if (this.messaging !== undefined) return this.messaging;
    if (!this.enabled) {
      this.messaging = null;
      return null;
    }
    try {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const admin = require('firebase-admin');
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId: this.config.get<string>('firebase.projectId'),
            clientEmail: this.config.get<string>('firebase.clientEmail'),
            // Env vars store the PEM with literal "\n"; restore real newlines.
            privateKey: this.config
              .get<string>('firebase.privateKey')
              ?.replace(/\\n/g, '\n'),
          }),
        });
      }
      this.messaging = admin.messaging() as Messaging;
    } catch (err) {
      this.logger.warn(
        `firebase-admin unavailable, push disabled: ${String(err)}`,
      );
      this.messaging = null;
    }
    return this.messaging;
  }
}
