import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { LedgerReason } from '@prisma/client';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { CharacterService } from '../../character/application/character.service';

/** Shape stored in BattlePassTier.freeReward / premiumReward JSON columns. */
interface TierReward {
  type: 'xp' | 'gold' | 'item';
  refKey?: string;
  amount: number;
}

/**
 * Seasonal Battle Pass: characters earn season XP by playing, which advances
 * their tier; each tier unlocks a free reward (and a richer premium reward for
 * Premium subscribers). Rewards are claimed explicitly and granted through the
 * shared {@link CharacterService.awardRewards} flow.
 */
@Injectable()
export class BattlePassService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly characters: CharacterService,
  ) {}

  /** The active season, its tiers, and this character's progress. */
  async current(characterId: string) {
    const season = await this.activeSeason();
    const [tiers, progress] = await Promise.all([
      this.prisma.battlePassTier.findMany({
        where: { seasonId: season.id },
        orderBy: { tier: 'asc' },
      }),
      this.getOrCreateProgress(characterId, season.id),
    ]);

    return {
      season: { id: season.id, name: season.name, startAt: season.startAt, endAt: season.endAt },
      tiers,
      progress: {
        xp: progress.xp,
        tier: progress.tier,
        isPremium: progress.isPremium,
        claimedTiers: progress.claimedTiers,
      },
    };
  }

  /**
   * Claim the reward for a tier. Validates that the tier has been reached, isn't
   * already claimed, and — for premium rewards — that the character holds the
   * premium pass. Grants the reward and records the tier as claimed.
   */
  async claim(characterId: string, tier: number) {
    const season = await this.activeSeason();
    const progress = await this.getOrCreateProgress(characterId, season.id);

    if (tier > progress.tier) {
      throw new BadRequestException('Tier not yet reached');
    }
    if (progress.claimedTiers.includes(tier)) {
      throw new BadRequestException('Tier already claimed');
    }

    const tierRow = await this.prisma.battlePassTier.findUnique({
      where: { seasonId_tier: { seasonId: season.id, tier } },
    });
    if (!tierRow) throw new NotFoundException('Tier not found');

    // Premium track requires the premium pass; free users get the free reward.
    const premium = tierRow.premiumReward as unknown as TierReward | null;
    const free = tierRow.freeReward as unknown as TierReward | null;
    let reward: TierReward | null;
    if (progress.isPremium) {
      reward = premium ?? free;
    } else {
      if (premium && !free) {
        throw new ForbiddenException('Premium pass required to claim this tier');
      }
      reward = free;
    }

    if (reward) {
      await this.characters.awardRewards({
        characterId,
        xp: reward.type === 'xp' ? reward.amount : 0,
        gold: reward.type === 'gold' ? reward.amount : 0,
        reason: LedgerReason.BATTLE_PASS,
        refId: `${season.id}:tier:${tier}`,
      });
    }

    const updated = await this.prisma.battlePassProgress.update({
      where: { characterId_seasonId: { characterId, seasonId: season.id } },
      data: { claimedTiers: { push: tier } },
    });

    return { claimedTiers: updated.claimedTiers, reward };
  }

  /**
   * Award season XP and advance the tier accordingly. Called by the completion
   * flows whenever a character earns XP during an active season.
   */
  async addXp(characterId: string, amount: number) {
    if (amount <= 0) return null;
    const season = await this.activeSeason();
    const progress = await this.getOrCreateProgress(characterId, season.id);

    const newXp = progress.xp + amount;
    const tier = await this.tierForXp(season.id, newXp);

    return this.prisma.battlePassProgress.update({
      where: { characterId_seasonId: { characterId, seasonId: season.id } },
      data: { xp: newXp, tier },
    });
  }

  private async activeSeason() {
    const season = await this.prisma.season.findFirst({
      where: { isActive: true },
      orderBy: { startAt: 'desc' },
    });
    if (!season) throw new NotFoundException('No active season');
    return season;
  }

  private async getOrCreateProgress(characterId: string, seasonId: string) {
    return (
      (await this.prisma.battlePassProgress.findUnique({
        where: { characterId_seasonId: { characterId, seasonId } },
      })) ??
      (await this.prisma.battlePassProgress.create({
        data: { characterId, seasonId },
      }))
    );
  }

  /** Highest tier whose cumulative XP requirement is met by `xp`. */
  private async tierForXp(seasonId: string, xp: number): Promise<number> {
    const reached = await this.prisma.battlePassTier.findFirst({
      where: { seasonId, xpRequired: { lte: xp } },
      orderBy: { tier: 'desc' },
      select: { tier: true },
    });
    return reached?.tier ?? 0;
  }
}
