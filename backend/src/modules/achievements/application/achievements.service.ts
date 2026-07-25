import { Injectable, NotFoundException } from '@nestjs/common';
import { LedgerReason } from '@prisma/client';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { CharacterService } from '../../character/application/character.service';
import {
  ACHIEVEMENT_CATALOG,
  AchievementDef,
} from '../domain/achievement-catalog';

@Injectable()
export class AchievementsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly characters: CharacterService,
  ) {}

  private async characterId(userId: string): Promise<string> {
    const c = await this.prisma.character.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!c) throw new NotFoundException('Character not found');
    return c.id;
  }

  /** List every achievement with the character's unlock status + progress. */
  async list(userId: string) {
    const characterId = await this.characterId(userId);
    const unlocked = await this.prisma.characterAchievement.findMany({
      where: { characterId },
    });
    const byId = new Map(unlocked.map((u) => [u.achievementId, u]));
    return ACHIEVEMENT_CATALOG.map((def) => ({
      ...def,
      unlocked: Boolean(byId.get(def.id)?.unlockedAt),
      progress: byId.get(def.id)?.progress ?? 0,
    }));
  }

  /**
   * Recompute which achievements the character has newly earned and grant their
   * rewards. Designed to run after meaningful events (quest complete, boss
   * defeat, level-up) — typically enqueued to the worker for async processing.
   */
  async evaluate(characterId: string): Promise<AchievementDef[]> {
    const stats = await this.gatherStats(characterId);
    const already = await this.prisma.characterAchievement.findMany({
      where: { characterId, unlockedAt: { not: null } },
      select: { achievementId: true },
    });
    const unlockedIds = new Set(already.map((a) => a.achievementId));
    const newlyUnlocked: AchievementDef[] = [];

    for (const def of ACHIEVEMENT_CATALOG) {
      if (unlockedIds.has(def.id)) continue;
      const value = this.statValue(stats, def);
      const progress = Math.min(1, value / def.criteria.threshold);
      if (value >= def.criteria.threshold) {
        await this.prisma.characterAchievement.upsert({
          where: {
            characterId_achievementId: {
              characterId,
              achievementId: def.id,
            },
          },
          create: {
            characterId,
            achievementId: def.id,
            progress: 1,
            unlockedAt: new Date(),
          },
          update: { progress: 1, unlockedAt: new Date() },
        });
        if (def.rewardXp || def.rewardGold) {
          await this.characters.awardRewards({
            characterId,
            xp: def.rewardXp,
            gold: def.rewardGold,
            reason: LedgerReason.ACHIEVEMENT_REWARD,
            refId: def.id,
          });
        }
        newlyUnlocked.push(def);
      } else if (progress > 0) {
        await this.prisma.characterAchievement.upsert({
          where: {
            characterId_achievementId: {
              characterId,
              achievementId: def.id,
            },
          },
          create: { characterId, achievementId: def.id, progress },
          update: { progress },
        });
      }
    }
    return newlyUnlocked;
  }

  private async gatherStats(characterId: string) {
    const [questsCompleted, character, streak, bossesDefeated, goldEarned] =
      await Promise.all([
        this.prisma.questCompletion.count({ where: { characterId } }),
        this.prisma.character.findUniqueOrThrow({ where: { id: characterId } }),
        this.prisma.streak.findUnique({ where: { characterId } }),
        this.prisma.boss.count({ where: { characterId, status: 'DEFEATED' } }),
        this.prisma.goldLedgerEntry.aggregate({
          where: { characterId, delta: { gt: 0 } },
          _sum: { delta: true },
        }),
      ]);
    return {
      QUESTS_COMPLETED: questsCompleted,
      CHARACTER_LEVEL: character.level,
      STREAK_DAYS: streak?.longest ?? 0,
      BOSSES_DEFEATED: bossesDefeated,
      GOLD_EARNED: goldEarned._sum.delta ?? 0,
    };
  }

  private statValue(
    stats: Record<string, number>,
    def: AchievementDef,
  ): number {
    return stats[def.criteria.type] ?? 0;
  }
}
