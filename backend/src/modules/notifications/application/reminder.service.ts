import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { LockService } from '../../../infra/redis/lock.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { periodKeyFor } from '../../../common/utils/period';
import { NotificationsService } from './notifications.service';

/**
 * Behaviour-based "smart" reminders. Rather than blasting every user, a daily
 * cron nudges only the people who have an incomplete daily quest today AND a
 * registered device — i.e. players at risk of breaking their routine who can
 * actually receive the push.
 */
@Injectable()
export class ReminderService {
  private readonly logger = new Logger(ReminderService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly locks: LockService,
  ) {}

  /** Every evening, remind users who still have an open daily quest. */
  @Cron(CronExpression.EVERY_DAY_AT_6PM)
  async sendDailyReminders(): Promise<void> {
    // Only one replica sends the batch (lock held for the hour of the tick).
    await this.locks.withLock('reminders:daily', 60 * 60 * 1000, async () => {
      const userIds = await this.usersNeedingReminder();
      if (userIds.length === 0) return;

      this.logger.log(`Sending daily reminders to ${userIds.length} user(s)`);
      await Promise.all(
        userIds.map((userId) =>
          this.notifications
            .send(userId, {
              title: 'Your quests are waiting ⚔️',
              body: 'You still have a daily quest to finish — keep your streak alive!',
              data: { type: 'daily_reminder' },
            })
            .catch(() => undefined),
        ),
      );
    });
  }

  /**
   * The distinct user ids that (a) own at least one ACTIVE daily quest with no
   * completion in today's period and (b) have a registered notification token.
   */
  async usersNeedingReminder(now: Date = new Date()): Promise<string[]> {
    const periodKey = periodKeyFor('DAILY', now);

    const quests = await this.prisma.quest.findMany({
      where: {
        status: 'ACTIVE',
        cadence: 'DAILY',
        completions: { none: { periodKey } },
        character: { user: { notificationTokens: { some: {} } } },
      },
      select: { character: { select: { userId: true } } },
      distinct: ['characterId'],
    });

    return [...new Set(quests.map((q) => q.character.userId))];
  }
}
