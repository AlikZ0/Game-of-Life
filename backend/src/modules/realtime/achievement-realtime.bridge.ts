import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import type Redis from 'ioredis';
import { RedisService } from '../../infra/redis/redis.service';
import {
  ACHIEVEMENT_UNLOCKED_CHANNEL,
  AchievementUnlockedEvent,
} from '../gamification/gamification.constants';
import { RealtimeGateway } from './realtime.gateway';

/**
 * API-side subscriber that turns worker-published achievement-unlock events
 * (delivered over Redis pub/sub) into real-time WebSocket toasts. Runs only in
 * the API process, which is where the socket connections live.
 */
@Injectable()
export class AchievementRealtimeBridge
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(AchievementRealtimeBridge.name);
  private subscriber?: Redis;

  constructor(
    private readonly redis: RedisService,
    private readonly gateway: RealtimeGateway,
  ) {}

  async onModuleInit(): Promise<void> {
    // A dedicated connection: a subscriber can't run normal commands.
    this.subscriber = this.redis.duplicate();
    this.subscriber.on('message', (channel, message) => {
      if (channel === ACHIEVEMENT_UNLOCKED_CHANNEL) this.onMessage(message);
    });
    try {
      await this.subscriber.subscribe(ACHIEVEMENT_UNLOCKED_CHANNEL);
    } catch (err) {
      this.logger.warn(
        `Could not subscribe to ${ACHIEVEMENT_UNLOCKED_CHANNEL}: ${String(err)}`,
      );
    }
  }

  /** Parse a published event and fan it out to the character's socket room. */
  onMessage(raw: string): void {
    let event: AchievementUnlockedEvent;
    try {
      event = JSON.parse(raw) as AchievementUnlockedEvent;
    } catch {
      this.logger.warn('Dropped malformed achievement-unlocked event');
      return;
    }
    if (!event.characterId || !event.achievements?.length) return;
    this.gateway.emitAchievementUnlocked(event.characterId, {
      achievements: event.achievements,
    });
  }

  async onModuleDestroy(): Promise<void> {
    await this.subscriber?.quit().catch(() => undefined);
  }
}
