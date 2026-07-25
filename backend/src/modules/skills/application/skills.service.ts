import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { levelProgress, xpForLevel } from '../../gamification/domain/leveling';

export interface SkillDto {
  id: string;
  key: string;
  name: string;
  icon: string;
  color: string;
  level: number;
  xp: number;
  xpToNext: number;
  progress: number;
  totalXp: string;
}

@Injectable()
export class SkillsService {
  constructor(private readonly prisma: PrismaService) {}

  private async characterIdFor(userId: string): Promise<string> {
    const character = await this.prisma.character.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!character) throw new NotFoundException('Character not found');
    return character.id;
  }

  async list(userId: string): Promise<SkillDto[]> {
    const characterId = await this.characterIdFor(userId);
    const skills = await this.prisma.skill.findMany({
      where: { characterId },
      orderBy: { totalXp: 'desc' },
    });
    return skills.map((s) => ({
      id: s.id,
      key: s.key,
      name: s.name,
      icon: s.icon,
      color: s.color,
      level: s.level,
      xp: s.xp,
      xpToNext: xpForLevel(s.level),
      progress: levelProgress({ level: s.level, xp: s.xp }),
      totalXp: s.totalXp.toString(),
    }));
  }

  /** Recent XP events for a skill — powers the history list and heatmap. */
  async history(userId: string, skillKey: string, limit = 60) {
    const characterId = await this.characterIdFor(userId);
    const skill = await this.prisma.skill.findUnique({
      where: { characterId_key: { characterId, key: skillKey } },
    });
    if (!skill) throw new NotFoundException('Skill not found');
    const events = await this.prisma.skillXpEvent.findMany({
      where: { skillId: skill.id },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
    return { skillKey, events };
  }

  /**
   * Aggregates skill XP per day for the last `days` days — a GitHub-style
   * contribution heatmap of self-improvement effort.
   */
  async heatmap(userId: string, days = 84) {
    const characterId = await this.characterIdFor(userId);
    const since = new Date(Date.now() - days * 86400000);
    const events = await this.prisma.skillXpEvent.findMany({
      where: { skill: { characterId }, createdAt: { gte: since } },
      select: { amount: true, createdAt: true },
    });
    const buckets = new Map<string, number>();
    for (const e of events) {
      const day = e.createdAt.toISOString().slice(0, 10);
      buckets.set(day, (buckets.get(day) ?? 0) + e.amount);
    }
    return Array.from(buckets.entries())
      .map(([date, xp]) => ({ date, xp }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }
}
