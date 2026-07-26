import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { LedgerReason } from '@prisma/client';
import { BattlePassService } from './battle-pass.service';

/**
 * Seasonal Battle Pass: XP → tier progression and tier-reward claiming with the
 * free/premium entitlement split. Prisma + CharacterService are mocked.
 */
describe('BattlePassService', () => {
  const season = {
    id: 'season1',
    name: 'Season 1',
    startAt: new Date('2026-07-01'),
    endAt: new Date('2026-09-01'),
    isActive: true,
  };

  function build(opts: {
    season?: unknown;
    progress?: Record<string, unknown> | null;
    tierRow?: Record<string, unknown> | null;
    tierForXp?: { tier: number } | null;
  }) {
    const progress = opts.progress ?? {
      characterId: 'c1',
      seasonId: 'season1',
      xp: 0,
      tier: 0,
      isPremium: false,
      claimedTiers: [],
    };
    const prisma = {
      season: {
        findFirst: jest
          .fn()
          .mockResolvedValue(opts.season === undefined ? season : opts.season),
      },
      battlePassTier: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(opts.tierRow ?? null),
        findFirst: jest.fn().mockResolvedValue(opts.tierForXp ?? null),
      },
      battlePassProgress: {
        findUnique: jest.fn().mockResolvedValue(progress),
        create: jest.fn().mockResolvedValue(progress),
        update: jest.fn().mockImplementation(({ data }) =>
          Promise.resolve({
            ...progress,
            ...data,
            claimedTiers: data.claimedTiers?.push
              ? [...(progress.claimedTiers as number[]), data.claimedTiers.push]
              : progress.claimedTiers,
          }),
        ),
      },
    };
    const characters = { awardRewards: jest.fn().mockResolvedValue({}) };
    const service = new BattlePassService(prisma as never, characters as never);
    return { service, prisma, characters };
  }

  // ── addXp ───────────────────────────────────────────────
  describe('addXp', () => {
    it('is a no-op for a non-positive amount', async () => {
      const { service, prisma } = build({});
      await expect(service.addXp('c1', 0)).resolves.toBeNull();
      expect(prisma.battlePassProgress.update).not.toHaveBeenCalled();
    });

    it('accumulates XP and advances the tier', async () => {
      const { service, prisma } = build({
        progress: {
          characterId: 'c1',
          seasonId: 'season1',
          xp: 100,
          tier: 1,
          isPremium: false,
          claimedTiers: [],
        },
        tierForXp: { tier: 3 },
      });
      await service.addXp('c1', 250);
      expect(prisma.battlePassProgress.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { xp: 350, tier: 3 } }),
      );
    });
  });

  // ── claim ───────────────────────────────────────────────
  describe('claim', () => {
    it('rejects claiming a tier not yet reached', async () => {
      const { service } = build({
        progress: {
          characterId: 'c1',
          seasonId: 'season1',
          xp: 0,
          tier: 1,
          isPremium: false,
          claimedTiers: [],
        },
      });
      await expect(service.claim('c1', 5)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('rejects claiming an already-claimed tier', async () => {
      const { service } = build({
        progress: {
          characterId: 'c1',
          seasonId: 'season1',
          xp: 0,
          tier: 3,
          isPremium: false,
          claimedTiers: [2],
        },
      });
      await expect(service.claim('c1', 2)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('404s when the tier row is missing', async () => {
      const { service } = build({
        progress: {
          characterId: 'c1',
          seasonId: 'season1',
          xp: 0,
          tier: 3,
          isPremium: false,
          claimedTiers: [],
        },
        tierRow: null,
      });
      await expect(service.claim('c1', 1)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('forbids a free user from claiming a premium-only tier', async () => {
      const { service } = build({
        progress: {
          characterId: 'c1',
          seasonId: 'season1',
          xp: 0,
          tier: 3,
          isPremium: false,
          claimedTiers: [],
        },
        tierRow: {
          tier: 1,
          freeReward: null,
          premiumReward: { type: 'gold', amount: 500 },
        },
      });
      await expect(service.claim('c1', 1)).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('grants a free user the free reward and records the claim', async () => {
      const { service, characters, prisma } = build({
        progress: {
          characterId: 'c1',
          seasonId: 'season1',
          xp: 0,
          tier: 3,
          isPremium: false,
          claimedTiers: [],
        },
        tierRow: {
          tier: 1,
          freeReward: { type: 'gold', amount: 50 },
          premiumReward: { type: 'gold', amount: 500 },
        },
      });
      const res = await service.claim('c1', 1);
      expect(characters.awardRewards).toHaveBeenCalledWith(
        expect.objectContaining({
          gold: 50,
          xp: 0,
          reason: LedgerReason.BATTLE_PASS,
          refId: 'season1:tier:1',
        }),
      );
      expect(prisma.battlePassProgress.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { claimedTiers: { push: 1 } } }),
      );
      expect(res.claimedTiers).toContain(1);
    });

    it('grants a premium user the richer premium reward', async () => {
      const { service, characters } = build({
        progress: {
          characterId: 'c1',
          seasonId: 'season1',
          xp: 0,
          tier: 3,
          isPremium: true,
          claimedTiers: [],
        },
        tierRow: {
          tier: 1,
          freeReward: { type: 'gold', amount: 50 },
          premiumReward: { type: 'xp', amount: 300 },
        },
      });
      await service.claim('c1', 1);
      expect(characters.awardRewards).toHaveBeenCalledWith(
        expect.objectContaining({ xp: 300, gold: 0 }),
      );
    });

    it('records the claim even when the tier has no reward', async () => {
      const { service, characters, prisma } = build({
        progress: {
          characterId: 'c1',
          seasonId: 'season1',
          xp: 0,
          tier: 3,
          isPremium: false,
          claimedTiers: [],
        },
        tierRow: { tier: 1, freeReward: null, premiumReward: null },
      });
      const res = await service.claim('c1', 1);
      expect(characters.awardRewards).not.toHaveBeenCalled();
      expect(prisma.battlePassProgress.update).toHaveBeenCalled();
      expect(res.reward).toBeNull();
    });
  });
});
