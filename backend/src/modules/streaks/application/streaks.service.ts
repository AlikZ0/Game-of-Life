import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { dayKey } from '../../../common/utils/period';

/** Streak milestones → bonus gold granted the day the milestone is reached. */
export const STREAK_MILESTONES: Record<number, number> = {
  3: 25,
  7: 75,
  14: 150,
  30: 400,
  60: 1000,
  100: 2500,
  365: 15000,
};

export interface StreakState {
  current: number;
  longest: number;
  freezeCount: number;
  lastActiveDay: string | null;
  milestoneReached?: number;
  bonusGold?: number;
}

@Injectable()
export class StreaksService {
  constructor(private readonly prisma: PrismaService) {}

  async get(characterId: string): Promise<StreakState> {
    const streak = await this.prisma.streak.findUnique({
      where: { characterId },
    });
    return {
      current: streak?.current ?? 0,
      longest: streak?.longest ?? 0,
      freezeCount: streak?.freezeCount ?? 0,
      lastActiveDay: streak?.lastActiveDay ?? null,
    };
  }

  /**
   * Registers activity for "today". Increments the streak on a consecutive day,
   * keeps it on same-day repeats, applies a freeze on a single skipped day, and
   * resets after a longer gap. Returns any milestone hit for reward granting.
   */
  async registerActivity(
    characterId: string,
    now: Date = new Date(),
  ): Promise<StreakState> {
    const today = dayKey(now);
    const yesterday = dayKey(new Date(now.getTime() - 86400000));

    const streak =
      (await this.prisma.streak.findUnique({ where: { characterId } })) ??
      (await this.prisma.streak.create({ data: { characterId } }));

    if (streak.lastActiveDay === today) {
      return this.toState(streak); // already counted today
    }

    let current = streak.current;
    let freezeCount = streak.freezeCount;

    if (streak.lastActiveDay === yesterday || streak.lastActiveDay === null) {
      current += 1;
    } else if (this.isGapOfOne(streak.lastActiveDay, today) && freezeCount > 0) {
      // A single missed day is absorbed by a streak freeze.
      freezeCount -= 1;
      current += 1;
    } else {
      current = 1; // streak broken → restart
    }

    const longest = Math.max(streak.longest, current);
    const bonusGold = STREAK_MILESTONES[current];

    const updated = await this.prisma.streak.update({
      where: { characterId },
      data: { current, longest, freezeCount, lastActiveDay: today },
    });

    const state = this.toState(updated);
    if (bonusGold) {
      state.milestoneReached = current;
      state.bonusGold = bonusGold;
    }
    return state;
  }

  private isGapOfOne(last: string | null, today: string): boolean {
    if (!last) return false;
    const diff =
      (Date.parse(today) - Date.parse(last)) / 86400000;
    return diff === 2; // exactly one full day skipped
  }

  private toState(s: {
    current: number;
    longest: number;
    freezeCount: number;
    lastActiveDay: string | null;
  }): StreakState {
    return {
      current: s.current,
      longest: s.longest,
      freezeCount: s.freezeCount,
      lastActiveDay: s.lastActiveDay,
    };
  }
}
