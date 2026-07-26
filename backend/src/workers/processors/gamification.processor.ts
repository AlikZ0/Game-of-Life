import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { AchievementsService } from '../../modules/achievements/application/achievements.service';
import { RedisService } from '../../infra/redis/redis.service';
import {
  ACHIEVEMENT_UNLOCKED_CHANNEL,
  AchievementUnlockedEvent,
  GAMIFICATION_QUEUE,
  GamificationJob,
} from '../../modules/gamification/gamification.constants';

/**
 * Consumes gamification jobs enqueued by the API after gameplay events.
 * Achievement evaluation is idempotent, so retries are safe.
 */
@Processor(GAMIFICATION_QUEUE)
export class GamificationProcessor extends WorkerHost {
  private readonly logger = new Logger(GamificationProcessor.name);

  constructor(
    private readonly achievements: AchievementsService,
    private readonly redis: RedisService,
  ) {
    super();
  }

  async process(job: Job<GamificationJob>): Promise<void> {
    const data = job.data;
    switch (data.type) {
      case 'evaluate-achievements': {
        const unlocked = await this.achievements.evaluate(data.characterId);
        if (unlocked.length) {
          this.logger.log(
            `Character ${data.characterId} unlocked ${unlocked.length} achievement(s)`,
          );
          await this.publishUnlocked(data.characterId, unlocked);
        }
        break;
      }
      case 'recompute-leaderboard':
        // Sprint: recompute guild weekly leaderboard + emit via RealtimeGateway.
        this.logger.debug(`Recompute leaderboard for guild ${data.guildId}`);
        break;
      default:
        this.logger.warn(`Unknown job type: ${JSON.stringify(job.name)}`);
    }
  }

  /**
   * Publish newly unlocked achievements so the API can push a live toast. The
   * worker holds no socket connections, so it bridges via Redis pub/sub.
   * Best-effort: a publish failure must not fail the (already-persisted) job.
   */
  private async publishUnlocked(
    characterId: string,
    unlocked: Array<{ id: string; name: string; rarity: string; icon: string }>,
  ): Promise<void> {
    const event: AchievementUnlockedEvent = {
      characterId,
      achievements: unlocked.map((a) => ({
        id: a.id,
        name: a.name,
        rarity: a.rarity,
        icon: a.icon,
      })),
    };
    try {
      await this.redis.publish(
        ACHIEVEMENT_UNLOCKED_CHANNEL,
        JSON.stringify(event),
      );
    } catch (err) {
      this.logger.warn(`Failed to publish unlock event: ${String(err)}`);
    }
  }
}
