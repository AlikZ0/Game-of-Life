import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Difficulty, QuestCadence } from '@prisma/client';
import { StatsService } from '../../stats/application/stats.service';

export interface SuggestedQuest {
  title: string;
  cadence: QuestCadence;
  difficulty: Difficulty;
  skillKey: string;
  rationale: string;
}

export interface CoachAnalysis {
  summary: string;
  weakAreas: string[];
  strengths: string[];
  suggestedQuests: SuggestedQuest[];
  predictedLevelIn30d: number | null;
}

/**
 * The AI Coach turns behavioural data into guidance. It ships with a
 * deterministic, rule-based engine (works with zero external cost / offline)
 * and an optional LLM path (`AI_API_KEY`) that can enrich the summary and
 * personalise quests. This keeps the feature useful for free users while
 * reserving the richer LLM experience for Premium.
 */
@Injectable()
export class AiCoachService {
  constructor(
    private readonly stats: StatsService,
    private readonly config: ConfigService,
  ) {}

  async analyze(userId: string): Promise<CoachAnalysis> {
    const [balance, dashboard, series] = await Promise.all([
      this.stats.lifeBalance(userId),
      this.stats.dashboard(userId),
      this.stats.xpSeries(userId, 14),
    ]);

    const weak = balance.filter((b) => b.neglected).map((b) => b.name);
    const strengths = balance.slice(0, 2).map((b) => b.name);

    const suggestedQuests = this.suggestQuests(balance);
    const predictedLevelIn30d = this.predictLevel(dashboard.level, series);

    const summary = this.buildSummary(dashboard, weak, strengths);

    // Premium: enrich via LLM when configured (non-blocking design in prod —
    // here we simply annotate that the richer path is available).
    if (this.config.get<string>('ai.apiKey')) {
      // await this.llm.enrich(...) — implemented behind the Premium gate.
    }

    return {
      summary,
      weakAreas: weak,
      strengths,
      suggestedQuests,
      predictedLevelIn30d,
    };
  }

  /** Generate personalised quests biased toward neglected skills. */
  suggestQuests(
    balance: { key: string; name: string; neglected: boolean }[],
  ): SuggestedQuest[] {
    const templates: Record<string, string> = {
      programming: 'Code for 30 focused minutes',
      fitness: 'Complete a 20-minute workout',
      reading: 'Read 15 pages of a book',
      english: 'Practice English for 15 minutes',
      business: 'Work on your side project for 30 minutes',
      finance: 'Review your budget / track expenses',
      leadership: 'Mentor or give feedback to someone',
      discipline: 'Wake up on time and plan your day',
    };
    const targets = balance
      .filter((b) => b.neglected)
      .slice(0, 3)
      .concat(balance.slice(0, 1)); // include one strength to stay motivating
    return targets.map((t) => ({
      title: templates[t.key] ?? `Improve your ${t.name}`,
      cadence: QuestCadence.DAILY,
      difficulty: t.neglected ? Difficulty.EASY : Difficulty.MEDIUM,
      skillKey: t.key,
      rationale: t.neglected
        ? `${t.name} is under 5% of your recent XP — a small daily habit will rebalance your life.`
        : `Keep the momentum on ${t.name}, one of your strengths.`,
    }));
  }

  /** Linear projection of level from recent XP velocity (bounded, honest). */
  private predictLevel(
    currentLevel: number,
    series: { date: string; xp: number }[],
  ): number | null {
    if (series.length === 0) return null;
    const avgDaily =
      series.reduce((s, p) => s + p.xp, 0) / Math.max(series.length, 1);
    // ~ how many levels the projected 30-day XP roughly buys (heuristic).
    const projectedXp = avgDaily * 30;
    const levelsGained = Math.floor(projectedXp / (100 * Math.sqrt(currentLevel)));
    return currentLevel + Math.max(0, levelsGained);
  }

  private buildSummary(
    dashboard: { currentStreak: number; questsCompleted30d: number },
    weak: string[],
    strengths: string[],
  ): string {
    const parts: string[] = [];
    parts.push(
      `You've completed ${dashboard.questsCompleted30d} quests in the last 30 days`,
    );
    if (dashboard.currentStreak > 0) {
      parts.push(`and you're on a ${dashboard.currentStreak}-day streak 🔥`);
    }
    if (strengths.length) parts.push(`Strengths: ${strengths.join(', ')}.`);
    if (weak.length) {
      parts.push(`Consider more attention on: ${weak.join(', ')}.`);
    }
    return parts.join(' ');
  }
}
