import { Difficulty } from '@prisma/client';

/**
 * Difficulty → reward/cost multipliers. Base quest rewards are authored as
 * "MEDIUM" values; the engine scales them at completion time. This keeps the
 * economy balanced and makes difficulty a meaningful choice.
 */
export const DIFFICULTY_MULTIPLIERS: Record<
  Difficulty,
  { xp: number; gold: number; energy: number; damage: number }
> = {
  TRIVIAL: { xp: 0.5, gold: 0.5, energy: 0.5, damage: 0.5 },
  EASY: { xp: 0.75, gold: 0.75, energy: 0.75, damage: 0.75 },
  MEDIUM: { xp: 1.0, gold: 1.0, energy: 1.0, damage: 1.0 },
  HARD: { xp: 1.6, gold: 1.5, energy: 1.4, damage: 1.6 },
  EPIC: { xp: 2.5, gold: 2.25, energy: 2.0, damage: 2.5 },
};

export interface RewardBundle {
  xp: number;
  gold: number;
  energyCost: number;
  damage: number;
}

export interface RewardInput {
  baseXp: number;
  baseGold: number;
  baseEnergyCost: number;
  baseDamage: number;
  difficulty: Difficulty;
  /** Optional streak bonus multiplier (e.g. 1.1 at a 7-day streak). */
  streakMultiplier?: number;
}

/** Compute the final rewards for completing a quest, rounded to whole units. */
export function computeReward(input: RewardInput): RewardBundle {
  const m = DIFFICULTY_MULTIPLIERS[input.difficulty];
  const streak = input.streakMultiplier ?? 1;
  return {
    xp: Math.round(input.baseXp * m.xp * streak),
    gold: Math.round(input.baseGold * m.gold * streak),
    energyCost: Math.round(input.baseEnergyCost * m.energy),
    damage: Math.round(input.baseDamage * m.damage),
  };
}

/**
 * Streak → reward multiplier. Gentle, capped bonus that rewards consistency
 * without punishing a missed day too harshly (healthy engagement).
 */
export function streakMultiplier(streakDays: number): number {
  if (streakDays >= 100) return 1.5;
  if (streakDays >= 30) return 1.3;
  if (streakDays >= 14) return 1.2;
  if (streakDays >= 7) return 1.1;
  if (streakDays >= 3) return 1.05;
  return 1.0;
}
