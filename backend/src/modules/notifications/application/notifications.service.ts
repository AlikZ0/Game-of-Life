import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { FcmSender } from '../infrastructure/fcm-sender';

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Delivers push notifications via Firebase Cloud Messaging. Firebase is optional:
 * when credentials are unset (local dev / CI) the service degrades to logging
 * the payload instead of sending, so the rest of the app never depends on cloud
 * credentials being present.
 */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly fcm: FcmSender,
  ) {}

  /** Register (or refresh) a device's FCM token for a user. */
  async registerToken(userId: string, fcmToken: string, platform: string) {
    return this.prisma.notificationToken.upsert({
      where: { fcmToken },
      update: { userId, platform },
      create: { userId, fcmToken, platform },
    });
  }

  /**
   * Send a push to every device registered for a user. Resolves the user's
   * tokens, dispatches through Firebase Admin (when configured), and prunes any
   * tokens FCM reports as permanently dead. A no-op fallback logs the payload
   * when Firebase isn't configured.
   */
  async send(userId: string, payload: PushPayload): Promise<void> {
    const tokens = await this.prisma.notificationToken.findMany({
      where: { userId },
      select: { fcmToken: true },
    });
    if (tokens.length === 0) return;

    if (!this.fcm.enabled) {
      this.logger.log(
        `[push:noop] ${userId} → "${payload.title}" (${tokens.length} device(s); Firebase not configured)`,
      );
      return;
    }

    const fcmTokens = tokens.map((t) => t.fcmToken);
    const dead = await this.fcm.sendMulticast(fcmTokens, payload);
    this.logger.log(
      `[push] "${payload.title}" → ${fcmTokens.length} device(s) for ${userId}` +
        (dead.length ? `, pruning ${dead.length} dead token(s)` : ''),
    );
    if (dead.length) {
      await this.prisma.notificationToken.deleteMany({
        where: { fcmToken: { in: dead } },
      });
    }
  }
}
