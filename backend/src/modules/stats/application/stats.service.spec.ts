import { NotFoundException } from '@nestjs/common';
import { StatsService } from './stats.service';

/**
 * Read-side analytics that feed the dashboard and the AI Coach: headline
 * totals, the daily XP time-series, and life-balance skill shares. Prisma is
 * mocked with controlled aggregates.
 */
describe('StatsService', () => {
  function build(opts: {
    character?: Record<string, unknown> | null;
    completionsCount?: number;
    activeQuests?: number;
    skills?: Array<Record<string, unknown>>;
    streak?: Record<string, unknown> | null;
    completions?: Array<{ xpAwarded: number; completedAt: Date }>;
  }) {
    const character =
      opts.character === undefined
        ? { id: 'c1', level: 7, totalXp: 4200n, gold: 350 }
        : opts.character;
    const prisma = {
      character: {
        findUnique: jest
          .fn()
          .mockResolvedValue(character === null ? null : { id: 'c1' }),
        findUniqueOrThrow: jest.fn().mockResolvedValue(character),
      },
      questCompletion: {
        count: jest.fn().mockResolvedValue(opts.completionsCount ?? 0),
        findMany: jest.fn().mockResolvedValue(opts.completions ?? []),
      },
      quest: { count: jest.fn().mockResolvedValue(opts.activeQuests ?? 0) },
      skill: { findMany: jest.fn().mockResolvedValue(opts.skills ?? []) },
      streak: {
        findUnique: jest.fn().mockResolvedValue(opts.streak ?? null),
      },
    };
    return { service: new StatsService(prisma as never), prisma };
  }

  // ── dashboard ───────────────────────────────────────────
  describe('dashboard', () => {
    it('throws NotFound when the user has no character', async () => {
      const { service } = build({ character: null });
      await expect(service.dashboard('u1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('assembles headline totals with a serialized BigInt totalXp', async () => {
      const { service } = build({
        completionsCount: 12,
        activeQuests: 4,
        streak: { current: 3, longest: 9 },
        skills: [{ key: 'fitness', name: 'Fitness', level: 2, totalXp: 300n }],
      });
      const res = await service.dashboard('u1');
      expect(res).toMatchObject({
        level: 7,
        totalXp: '4200',
        gold: 350,
        questsCompleted30d: 12,
        activeQuests: 4,
        currentStreak: 3,
        longestStreak: 9,
      });
      expect(res.skillBalance).toEqual([
        { key: 'fitness', name: 'Fitness', level: 2, totalXp: '300' },
      ]);
    });

    it('defaults streaks to zero when no streak row exists', async () => {
      const { service } = build({ streak: null });
      const res = await service.dashboard('u1');
      expect(res.currentStreak).toBe(0);
      expect(res.longestStreak).toBe(0);
    });
  });

  // ── xpSeries ────────────────────────────────────────────
  describe('xpSeries', () => {
    it('buckets XP by day and returns it sorted ascending', async () => {
      const { service } = build({
        completions: [
          { xpAwarded: 30, completedAt: new Date('2026-07-20T09:00:00Z') },
          { xpAwarded: 20, completedAt: new Date('2026-07-20T18:00:00Z') },
          { xpAwarded: 50, completedAt: new Date('2026-07-22T10:00:00Z') },
        ],
      });
      const series = await service.xpSeries('u1', 14);
      expect(series).toEqual([
        { date: '2026-07-20', xp: 50 },
        { date: '2026-07-22', xp: 50 },
      ]);
    });

    it('is empty when there are no completions', async () => {
      const { service } = build({ completions: [] });
      await expect(service.xpSeries('u1')).resolves.toEqual([]);
    });
  });

  // ── lifeBalance ─────────────────────────────────────────
  describe('lifeBalance', () => {
    it('computes shares, flags neglected skills, sorts by share desc', async () => {
      const { service } = build({
        skills: [
          { key: 'programming', name: 'Programming', totalXp: 900n },
          { key: 'fitness', name: 'Fitness', totalXp: 100n },
          { key: 'reading', name: 'Reading', totalXp: 20n }, // 20/1020 < 5%
        ],
      });
      const balance = await service.lifeBalance('u1');
      expect(balance.map((b) => b.key)).toEqual([
        'programming',
        'fitness',
        'reading',
      ]);
      expect(balance[0].share).toBeCloseTo(900 / 1020);
      expect(balance.find((b) => b.key === 'reading')?.neglected).toBe(true);
      expect(balance.find((b) => b.key === 'programming')?.neglected).toBe(
        false,
      );
    });

    it('avoids divide-by-zero when no skill has XP', async () => {
      const { service } = build({
        skills: [{ key: 'fitness', name: 'Fitness', totalXp: 0n }],
      });
      const balance = await service.lifeBalance('u1');
      expect(balance[0].share).toBe(0);
      expect(balance[0].neglected).toBe(true);
    });
  });
});
