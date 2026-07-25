import { Difficulty, QuestCadence, QuestStatus } from '@prisma/client';
import { QuestsService } from './quests.service';

/**
 * Unit test for the completion side-effects: real-time level-up / boss-defeat
 * emits and the async achievement-evaluation enqueue. All collaborators are
 * mocked so this runs without a database.
 */
describe('QuestsService.complete side-effects', () => {
  const characterId = 'char_1';

  const quest = {
    id: 'quest_1',
    characterId,
    status: QuestStatus.ACTIVE,
    cadence: QuestCadence.DAILY,
    difficulty: Difficulty.MEDIUM,
    xpReward: 100,
    goldReward: 50,
    energyCost: 10,
    damage: 10,
    skillKey: 'programming',
    bossId: 'boss_1',
  };

  function build(overrides: { levelsGained: number; bossDefeated: boolean }) {
    const realtime = {
      emitLevelUp: jest.fn(),
      emitBossDefeated: jest.fn(),
    };
    const queue = { add: jest.fn().mockResolvedValue(undefined) };

    const quests = {
      findById: jest.fn().mockResolvedValue(quest),
      update: jest.fn().mockResolvedValue(quest),
    };
    const prisma = {
      character: {
        findUnique: jest.fn().mockResolvedValue({ id: characterId }),
      },
      questCompletion: { create: jest.fn().mockResolvedValue({}) },
    };
    const characters = {
      awardRewards: jest.fn().mockResolvedValue({
        character: { level: 1 + overrides.levelsGained },
        levelsGained: overrides.levelsGained,
        goldBalance: 999,
      }),
    };
    const bosses = {
      applyDamage: jest
        .fn()
        .mockResolvedValue({ defeated: overrides.bossDefeated }),
    };
    const streaks = {
      registerActivity: jest
        .fn()
        .mockResolvedValue({ current: 1, bonusGold: 0 }),
    };
    const guilds = {
      recordWeeklyXp: jest.fn().mockResolvedValue(undefined),
    };

    const service = new QuestsService(
      quests as never,
      prisma as never,
      characters as never,
      bosses as never,
      streaks as never,
      realtime as never,
      guilds as never,
      queue as never,
    );
    return { service, realtime, queue, characters, bosses, guilds };
  }

  it('emits level-up when the character gains a level', async () => {
    const { service, realtime } = build({
      levelsGained: 2,
      bossDefeated: false,
    });
    await service.complete('user_1', quest.id);
    expect(realtime.emitLevelUp).toHaveBeenCalledWith(
      characterId,
      expect.objectContaining({ levelsGained: 2 }),
    );
  });

  it('does not emit level-up when no level was gained', async () => {
    const { service, realtime } = build({
      levelsGained: 0,
      bossDefeated: false,
    });
    await service.complete('user_1', quest.id);
    expect(realtime.emitLevelUp).not.toHaveBeenCalled();
  });

  it('emits boss-defeated when a linked boss reaches 0 HP', async () => {
    const { service, realtime } = build({
      levelsGained: 0,
      bossDefeated: true,
    });
    await service.complete('user_1', quest.id);
    expect(realtime.emitBossDefeated).toHaveBeenCalledWith(
      characterId,
      expect.objectContaining({ bossId: 'boss_1' }),
    );
  });

  it('enqueues achievement evaluation on every completion', async () => {
    const { service, queue } = build({ levelsGained: 0, bossDefeated: false });
    await service.complete('user_1', quest.id);
    expect(queue.add).toHaveBeenCalledWith(
      'evaluate-achievements',
      expect.objectContaining({ type: 'evaluate-achievements', characterId }),
      expect.any(Object),
    );
  });
});
