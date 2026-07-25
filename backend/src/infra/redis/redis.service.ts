import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

/**
 * Shared Redis connection (separate from BullMQ's own connections) used for
 * readiness checks and general caching. Fails fast rather than queuing commands
 * offline so a health probe reflects reality.
 */
@Injectable()
export class RedisService extends Redis implements OnModuleDestroy {
  constructor(config: ConfigService) {
    super({
      host: config.get<string>('redis.host', 'localhost'),
      port: config.get<number>('redis.port', 6379),
      maxRetriesPerRequest: 1,
      enableOfflineQueue: false,
      lazyConnect: true,
    });
  }

  /** Ping with a short timeout; returns true only if Redis answers. */
  async isHealthy(): Promise<boolean> {
    try {
      if (this.status !== 'ready') await this.connect().catch(() => undefined);
      const pong = await this.ping();
      return pong === 'PONG';
    } catch {
      return false;
    }
  }

  async onModuleDestroy(): Promise<void> {
    await this.quit().catch(() => undefined);
  }
}
