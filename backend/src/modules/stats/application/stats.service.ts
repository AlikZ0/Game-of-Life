import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';

@Injectable()
export class StatsService {
  constructor(private readonly prisma: PrismaService) {}

  private async characterId(userId: string): Promise<string> {
    const c = await this.prisma.character.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!c) throw new NotFoundException('Character not found');
    return c.id;
  }

  /** Headline dashboard: totals, completion rate, streak, skill balance. */
  async dashboard(userId: string) {
    const characterId = await this.characterId(userId);
    const since = new Date(Date.now() - 30 * 86400000);

    const [character, completions, activeQuests, skills, streak] =
      await Promise.all([
        this.prisma.character.findUniqueOrThrow({ where: { id: characterId } }),
        this.prisma.questCompletion.count({
          where: { characterId, completedAt: { gte: since } },
        }),
        this.prisma.quest.count({
          where: { characterId, status: 'ACTIVE' },
        }),
        this.prisma.skill.findMany({ where: { characterId } }),
        this.prisma.streak.findUnique({ where: { characterId } }),
      ]);

    return {
      level: character.level,
      totalXp: character.totalXp.toString(),
      gold: character.gold,
      questsCompleted30d: completions,
      activeQuests,
      currentStreak: streak?.current ?? 0,
      longestStreak: streak?.longest ?? 0,
      skillBalance: skills.map((s) => ({
        key: s.key,
        name: s.name,
        level: s.level,
        totalXp: s.totalXp.toString(),
      })),
    };
  }

  /** Daily XP time-series for charts over the given window. */
  async xpSeries(userId: string, days = 30) {
    const characterId = await this.characterId(userId);
    const since = new Date(Date.now() - days * 86400000);
    const completions = await this.prisma.questCompletion.findMany({
      where: { characterId, completedAt: { gte: since } },
      select: { xpAwarded: true, completedAt: true },
    });
    const buckets = new Map<string, number>();
    for (const c of completions) {
      const day = c.completedAt.toISOString().slice(0, 10);
      buckets.set(day, (buckets.get(day) ?? 0) + c.xpAwarded);
    }
    return Array.from(buckets.entries())
      .map(([date, xp]) => ({ date, xp }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }

  /**
   * Life-balance analysis: share of XP per skill, flagging neglected areas.
   * Feeds the "weak area" hints on the dashboard and the AI Coach.
   */
  async lifeBalance(userId: string) {
    const characterId = await this.characterId(userId);
    const skills = await this.prisma.skill.findMany({ where: { characterId } });
    const total = skills.reduce((sum, s) => sum + Number(s.totalXp), 0) || 1;
    return skills
      .map((s) => ({
        key: s.key,
        name: s.name,
        share: Number(s.totalXp) / total,
        neglected: Number(s.totalXp) / total < 0.05,
      }))
      .sort((a, b) => b.share - a.share);
  }
}
