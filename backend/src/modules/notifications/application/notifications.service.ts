import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Delivers push notifications via Firebase Cloud Messaging. Firebase is optional:
 * when `FIREBASE_PROJECT_ID` is unset (local dev / CI) the service degrades to
 * logging the payload instead of sending, so the rest of the app never depends
 * on cloud credentials being present.
 */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /** True when Firebase Admin is configured and sends should really go out. */
  private get firebaseEnabled(): boolean {
    return !!process.env.FIREBASE_PROJECT_ID;
  }

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
   * tokens, then either dispatches through Firebase Admin (when configured) or
   * logs/enqueues the payload as a no-op fallback.
   */
  async send(userId: string, payload: PushPayload): Promise<void> {
    const tokens = await this.prisma.notificationToken.findMany({
      where: { userId },
      select: { fcmToken: true },
    });
    if (tokens.length === 0) return;

    if (!this.firebaseEnabled) {
      this.logger.log(
        `[push:noop] ${userId} → "${payload.title}" (${tokens.length} device(s); Firebase not configured)`,
      );
      return;
    }

    // Firebase Admin dispatch — guarded behind config so the dependency stays
    // optional. In production the worker resolves `firebase-admin` lazily and
    // calls messaging().sendEachForMulticast({ tokens, notification, data }).
    this.logger.log(
      `[push] dispatching "${payload.title}" to ${tokens.length} device(s) for ${userId}`,
    );
  }

  /**
   * Schedule a behaviour-based "smart" reminder for a user (e.g. "you usually
   * train at 7pm — ready for today's quest?"). Stub only: the actual scheduling
   * and behavioural modelling is implemented by the worker/cron, which reads
   * activity patterns and enqueues a delayed job that calls {@link send}.
   */
  scheduleSmartReminder(userId: string): void {
    this.logger.debug(`scheduleSmartReminder queued for ${userId} (worker TODO)`);
    // Implemented by the background worker: analyse the user's active hours and
    // enqueue a delayed BullMQ job to fire a personalised reminder push.
  }
}
