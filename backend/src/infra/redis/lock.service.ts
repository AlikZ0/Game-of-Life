import { randomUUID } from 'crypto';
import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from './redis.service';

// Release atomically: delete the key only if it still holds *our* token, so a
// job that overran its TTL can never delete a lock a different replica has since
// acquired.
const RELEASE_SCRIPT = `
if redis.call("get", KEYS[1]) == ARGV[1] then
  return redis.call("del", KEYS[1])
else
  return 0
end`;

/**
 * A best-effort distributed lock over Redis (SET NX PX). It guards scheduled
 * jobs so that, when the API/worker runs with multiple replicas, a given cron
 * tick executes on exactly one of them. If Redis is unreachable the lock is
 * *not* granted, so the job is skipped rather than risking duplicate work.
 */
@Injectable()
export class LockService {
  private readonly logger = new Logger(LockService.name);

  constructor(private readonly redis: RedisService) {}

  /**
   * Run `fn` only if this replica wins `key`; otherwise skip and return null.
   * The lock auto-expires after `ttlMs` (a safety net if the process dies) and
   * is released on completion.
   */
  async withLock<T>(
    key: string,
    ttlMs: number,
    fn: () => Promise<T>,
  ): Promise<T | null> {
    const token = await this.acquire(key, ttlMs);
    if (!token) return null;
    try {
      return await fn();
    } finally {
      await this.release(key, token);
    }
  }

  /** Try to grab the lock; returns a release token on success, null otherwise. */
  async acquire(key: string, ttlMs: number): Promise<string | null> {
    const token = randomUUID();
    try {
      if (this.redis.status !== 'ready') {
        await this.redis.connect().catch(() => undefined);
      }
      const res = await this.redis.set(
        this.redisKey(key),
        token,
        'PX',
        ttlMs,
        'NX',
      );
      return res === 'OK' ? token : null;
    } catch (err) {
      this.logger.warn(`Lock acquire failed for "${key}": ${String(err)}`);
      return null;
    }
  }

  /** Release the lock if — and only if — we still own it. */
  async release(key: string, token: string): Promise<void> {
    try {
      await this.redis.eval(RELEASE_SCRIPT, 1, this.redisKey(key), token);
    } catch (err) {
      this.logger.warn(`Lock release failed for "${key}": ${String(err)}`);
    }
  }

  private redisKey(key: string): string {
    return `lock:${key}`;
  }
}
