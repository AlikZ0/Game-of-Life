import { LedgerReason } from '@prisma/client';
import { AchievementsService } from './achievements.service';

/**
 * The achievement unlock engine: it turns a character's aggregate stats into
 * newly-earned achievements, records partial progress, grants rewards, and
 * never re-unlocks. Prisma + CharacterService are mocked.
 */
describe('AchievementsService.evaluate', () => {
  function build(opts: {
    questsCompleted?: number;
    level?: number;
    longestStreak?: number;
    bossesDefeated?: number;
    goldEarned?: number;
    alreadyUnlocked?: string[];
  }) {
    const upsert = jest.fn().mockResolvedValue({});
    const prisma = {
      questCompletion: {
        count: jest.fn().mockResolvedValue(opts.questsCompleted ?? 0),
      },
      character: {
        findUniqueOrThrow: jest
          .fn()
          .mockResolvedValue({ level: opts.level ?? 1 }),
      },
      streak: {
        findUnique: jest
          .fn()
          .mockResolvedValue({ longest: opts.longestStreak ?? 0 }),
      },
      boss: {
        count: jest.fn().mockResolvedValue(opts.bossesDefeated ?? 0),
      },
      goldLedgerEntry: {
        aggregate: jest
          .fn()
          .mockResolvedValue({ _sum: { delta: opts.goldEarned ?? 0 } }),
      },
      characterAchievement: {
        findMany: jest.fn().mockResolvedValue(
          (opts.alreadyUnlocked ?? []).map((achievementId) => ({
            achievementId,
          })),
        ),
        upsert,
      },
    };
    const characters = { awardRewards: jest.fn().mockResolvedValue({}) };
    const service = new AchievementsService(
      prisma as never,
      characters as never,
    );
    return { service, prisma, characters, upsert };
  }

  it('unlocks an achievement when its threshold is met and grants its reward', async () => {
    const { service, characters, upsert } = build({ bossesDefeated: 1 });

    const unlocked = await service.evaluate('c1');

    const ids = unlocked.map((d) => d.id);
    expect(ids).toContain('first_boss');
    // reward granted for the unlock, tagged with the achievement id
    expect(characters.awardRewards).toHaveBeenCalledWith(
      expect.objectContaining({
        characterId: 'c1',
        reason: LedgerReason.ACHIEVEMENT_REWARD,
        refId: 'first_boss',
      }),
    );
    // the unlock is persisted with an unlockedAt timestamp
    const firstBossUpsert = upsert.mock.calls.find(
      ([arg]) =>
        arg.where.characterId_achievementId.achievementId === 'first_boss',
    );
    expect(firstBossUpsert[0].create.unlockedAt).toBeInstanceOf(Date);
  });

  it('records partial progress without unlocking or rewarding', async () => {
    const { service, characters, upsert } = build({ questsCompleted: 5 });

    const unlocked = await service.evaluate('c1');

    // 5/10 quests → the bronze quest achievement is not yet earned
    expect(unlocked.map((d) => d.id)).not.toContain('quests_completed_10');
    const progressUpsert = upsert.mock.calls.find(
      ([arg]) =>
        arg.where.characterId_achievementId.achievementId ===
        'quests_completed_10',
    );
    expect(progressUpsert[0].update.progress).toBeCloseTo(0.5);
    expect(progressUpsert[0].create.unlockedAt).toBeUndefined();
    expect(characters.awardRewards).not.toHaveBeenCalled();
  });

  it('does not re-unlock an already-earned achievement', async () => {
    const { service, characters } = build({
      bossesDefeated: 1,
      alreadyUnlocked: ['first_boss'],
    });

    const unlocked = await service.evaluate('c1');

    expect(unlocked.map((d) => d.id)).not.toContain('first_boss');
    expect(characters.awardRewards).not.toHaveBeenCalledWith(
      expect.objectContaining({ refId: 'first_boss' }),
    );
  });

  it('returns an empty list when no thresholds are met', async () => {
    const { service } = build({});
    await expect(service.evaluate('c1')).resolves.toEqual([]);
  });
});
