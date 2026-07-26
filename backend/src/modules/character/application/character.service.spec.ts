import { NotFoundException } from '@nestjs/common';
import { LedgerReason } from '@prisma/client';
import { CharacterService } from './character.service';

/**
 * The atomic progression engine: XP → levels, gold ledger, skill XP and energy.
 * The repository's transaction runs the callback against a controllable `tx`
 * mock; the real leveling domain math is exercised end-to-end.
 */
describe('CharacterService.awardRewards', () => {
  const baseCharacter = {
    id: 'c1',
    name: 'Aria',
    avatarKey: 'default',
    characterClass: 'WARRIOR',
    level: 1,
    xp: 0,
    totalXp: 0n,
    gold: 100,
    hp: 80,
    maxHp: 100,
    energy: 60,
    maxEnergy: 100,
    activeTitle: null,
  };

  function build(character: Record<string, unknown> | null, skill?: unknown) {
    const tx = {
      character: {
        findUnique: jest.fn().mockResolvedValue(character),
        update: jest
          .fn()
          .mockImplementation(({ data }) =>
            Promise.resolve({ ...baseCharacter, ...data }),
          ),
      },
      goldLedgerEntry: { create: jest.fn().mockResolvedValue({}) },
      skill: {
        findUnique: jest.fn().mockResolvedValue(skill ?? null),
        update: jest.fn().mockResolvedValue({}),
      },
      skillXpEvent: { create: jest.fn().mockResolvedValue({}) },
    };
    const repo = {
      transaction: jest.fn((fn) => fn(tx)),
    };
    return { service: new CharacterService(repo as never), tx };
  }

  it('throws NotFound when the character is missing', async () => {
    const { service } = build(null);
    await expect(
      service.awardRewards({
        characterId: 'missing',
        xp: 10,
        gold: 0,
        reason: LedgerReason.QUEST_REWARD,
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('levels up on a large XP gain and heals to full', async () => {
    const { service, tx } = build({ ...baseCharacter });
    const res = await service.awardRewards({
      characterId: 'c1',
      xp: 1000, // well past xpForLevel(1)=100
      gold: 0,
      reason: LedgerReason.QUEST_REWARD,
    });
    expect(res.levelsGained).toBeGreaterThan(0);
    const data = tx.character.update.mock.calls[0][0].data;
    // healed to the new (higher) maxHp on level-up
    expect(data.hp).toBe(data.maxHp);
    expect(data.maxHp).toBeGreaterThan(100);
  });

  it('does not level up on a small XP gain and never over-heals', async () => {
    const { service, tx } = build({ ...baseCharacter });
    const res = await service.awardRewards({
      characterId: 'c1',
      xp: 50, // below xpForLevel(1)=100
      gold: 0,
      reason: LedgerReason.QUEST_REWARD,
    });
    expect(res.levelsGained).toBe(0);
    const data = tx.character.update.mock.calls[0][0].data;
    expect(data.hp).toBe(80); // min(current hp, maxHp), unchanged
  });

  it('writes a gold-ledger entry with the running balance when gold changes', async () => {
    const { service, tx } = build({ ...baseCharacter });
    const res = await service.awardRewards({
      characterId: 'c1',
      xp: 0,
      gold: 25,
      reason: LedgerReason.QUEST_REWARD,
      refId: 'q1',
    });
    expect(res.goldBalance).toBe(125);
    expect(tx.goldLedgerEntry.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        characterId: 'c1',
        delta: 25,
        balance: 125,
        reason: LedgerReason.QUEST_REWARD,
        refId: 'q1',
      }),
    });
  });

  it('skips the ledger entry when gold does not change', async () => {
    const { service, tx } = build({ ...baseCharacter });
    await service.awardRewards({
      characterId: 'c1',
      xp: 10,
      gold: 0,
      reason: LedgerReason.QUEST_REWARD,
    });
    expect(tx.goldLedgerEntry.create).not.toHaveBeenCalled();
  });

  it('applies skill XP and records a skill event when a skill is targeted', async () => {
    const { service, tx } = build(
      { ...baseCharacter },
      {
        id: 's1',
        level: 1,
        xp: 0,
      },
    );
    await service.awardRewards({
      characterId: 'c1',
      xp: 40,
      gold: 0,
      skillKey: 'programming',
      reason: LedgerReason.QUEST_REWARD,
      refId: 'q1',
    });
    expect(tx.skill.update).toHaveBeenCalled();
    expect(tx.skillXpEvent.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ skillId: 's1', amount: 40 }),
    });
  });

  it('ignores skill XP when the targeted skill does not exist', async () => {
    const { service, tx } = build({ ...baseCharacter }, null);
    await service.awardRewards({
      characterId: 'c1',
      xp: 40,
      gold: 0,
      skillKey: 'nonexistent',
      reason: LedgerReason.QUEST_REWARD,
    });
    expect(tx.skill.update).not.toHaveBeenCalled();
    expect(tx.skillXpEvent.create).not.toHaveBeenCalled();
  });

  it('clamps energy to zero when the cost exceeds the current pool', async () => {
    const { service, tx } = build({ ...baseCharacter, energy: 5 });
    await service.awardRewards({
      characterId: 'c1',
      xp: 10,
      gold: 0,
      energyCost: 20,
      reason: LedgerReason.QUEST_REWARD,
    });
    const data = tx.character.update.mock.calls[0][0].data;
    expect(data.energy).toBe(0);
  });
});
