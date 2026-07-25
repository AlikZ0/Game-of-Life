import { Rarity } from '@prisma/client';

/**
 * Machine-readable achievement criteria. The engine evaluates a character's
 * aggregate stats against these rules. "Tiered families" (e.g. complete N
 * quests at 10/50/100/500/1000) let a handful of definitions expand into the
 * hundreds of achievements the product calls for.
 */
export type CriteriaType =
  | 'QUESTS_COMPLETED'
  | 'CHARACTER_LEVEL'
  | 'SKILL_LEVEL'
  | 'STREAK_DAYS'
  | 'BOSSES_DEFEATED'
  | 'GOLD_EARNED';

export interface AchievementDef {
  id: string;
  name: string;
  description: string;
  rarity: Rarity;
  icon: string;
  category: 'quests' | 'skills' | 'streaks' | 'social' | 'economy' | 'meta';
  rewardXp: number;
  rewardGold: number;
  criteria: { type: CriteriaType; threshold: number; skillKey?: string };
  isSecret?: boolean;
}

/** Tiered family generator: turns one theme into bronze→legendary rungs. */
function family(
  base: string,
  name: (n: number) => string,
  description: (n: number) => string,
  category: AchievementDef['category'],
  type: CriteriaType,
  icon: string,
  tiers: { threshold: number; rarity: Rarity; xp: number; gold: number }[],
): AchievementDef[] {
  return tiers.map((t) => ({
    id: `${base}_${t.threshold}`,
    name: name(t.threshold),
    description: description(t.threshold),
    rarity: t.rarity,
    icon,
    category,
    rewardXp: t.xp,
    rewardGold: t.gold,
    criteria: { type, threshold: t.threshold },
  }));
}

const QUEST_TIERS = [
  { threshold: 10, rarity: Rarity.BRONZE, xp: 50, gold: 25 },
  { threshold: 50, rarity: Rarity.SILVER, xp: 150, gold: 75 },
  { threshold: 100, rarity: Rarity.GOLD, xp: 400, gold: 200 },
  { threshold: 500, rarity: Rarity.GOLD, xp: 1500, gold: 750 },
  { threshold: 1000, rarity: Rarity.LEGENDARY, xp: 5000, gold: 2500 },
];

const STREAK_TIERS = [
  { threshold: 3, rarity: Rarity.BRONZE, xp: 40, gold: 20 },
  { threshold: 7, rarity: Rarity.BRONZE, xp: 100, gold: 50 },
  { threshold: 30, rarity: Rarity.SILVER, xp: 500, gold: 250 },
  { threshold: 100, rarity: Rarity.GOLD, xp: 2000, gold: 1000 },
  { threshold: 365, rarity: Rarity.LEGENDARY, xp: 12000, gold: 6000 },
];

const LEVEL_TIERS = [
  { threshold: 5, rarity: Rarity.BRONZE, xp: 0, gold: 50 },
  { threshold: 10, rarity: Rarity.SILVER, xp: 0, gold: 150 },
  { threshold: 25, rarity: Rarity.GOLD, xp: 0, gold: 600 },
  { threshold: 50, rarity: Rarity.LEGENDARY, xp: 0, gold: 3000 },
];

export const ACHIEVEMENT_CATALOG: AchievementDef[] = [
  ...family(
    'quests_completed',
    (n) => (n >= 1000 ? 'Living Legend' : `Quest Runner ${n}`),
    (n) => `Complete ${n} quests`,
    'quests',
    'QUESTS_COMPLETED',
    'sword',
    QUEST_TIERS,
  ),
  ...family(
    'streak',
    (n) => (n >= 365 ? 'Unbreakable' : `${n}-Day Streak`),
    (n) => `Maintain a ${n}-day streak`,
    'streaks',
    'STREAK_DAYS',
    'flame',
    STREAK_TIERS,
  ),
  ...family(
    'level',
    (n) => `Reach Level ${n}`,
    (n) => `Reach character level ${n}`,
    'meta',
    'CHARACTER_LEVEL',
    'star',
    LEVEL_TIERS,
  ),
  {
    id: 'first_boss',
    name: 'Giant Slayer',
    description: 'Defeat your first boss',
    rarity: Rarity.SILVER,
    icon: 'skull',
    category: 'quests',
    rewardXp: 300,
    rewardGold: 150,
    criteria: { type: 'BOSSES_DEFEATED', threshold: 1 },
  },
  {
    id: 'boss_hunter',
    name: 'Boss Hunter',
    description: 'Defeat 10 bosses',
    rarity: Rarity.GOLD,
    icon: 'skull',
    category: 'quests',
    rewardXp: 2000,
    rewardGold: 1000,
    criteria: { type: 'BOSSES_DEFEATED', threshold: 10 },
  },
  {
    id: 'gold_hoarder',
    name: 'Gold Hoarder',
    description: 'Earn 10,000 total gold',
    rarity: Rarity.GOLD,
    icon: 'coins',
    category: 'economy',
    rewardXp: 500,
    rewardGold: 0,
    criteria: { type: 'GOLD_EARNED', threshold: 10000 },
  },
];
