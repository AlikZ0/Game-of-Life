import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { AchievementsService } from '../../modules/achievements/application/achievements.service';

export const GAMIFICATION_QUEUE = 'gamification';

export type GamificationJob =
  | { type: 'evaluate-achievements'; characterId: string }
  | { type: 'recompute-leaderboard'; guildId: string };

/**
 * Consumes gamification jobs enqueued by the API after gameplay events.
 * Achievement evaluation is idempotent, so retries are safe.
 */
@Processor(GAMIFICATION_QUEUE)
export class GamificationProcessor extends WorkerHost {
  private readonly logger = new Logger(GamificationProcessor.name);

  constructor(private readonly achievements: AchievementsService) {
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
}
