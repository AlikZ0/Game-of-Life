/**
 * Pure, dependency-free progression math — the single source of truth for how
 * XP converts to levels across characters and skills. Kept in the domain layer
 * so it is trivially unit-testable and shared by every context.
 *
 * Curve: xpForLevel(n) = floor(BASE * n^EXP)
 *   - Super-linear (EXP > 1) so each level is meaningfully harder than the last,
 *     but not so steep that mid-game stalls. Tunable via BASE/EXP.
 */
export const XP_CURVE = {
  BASE: 100,
  EXP: 1.5,
} as const;

/** XP required to advance FROM `level` to `level + 1`. */
export function xpForLevel(level: number): number {
  if (level < 1) return 0;
  return Math.floor(XP_CURVE.BASE * Math.pow(level, XP_CURVE.EXP));
}

/** Cumulative XP needed to reach `level` from level 1. */
export function cumulativeXpForLevel(level: number): number {
  let total = 0;
  for (let n = 1; n < level; n++) total += xpForLevel(n);
  return total;
}

export interface Progression {
  level: number;
  /** XP accumulated within the current level (0 .. xpForLevel(level)-1). */
  xp: number;
}

export interface LevelUpResult extends Progression {
  levelsGained: number;
  /** Total XP threshold for the (new) current level, for progress bars. */
  xpToNext: number;
}

/**
 * Apply an XP gain to a progression, rolling over as many levels as the amount
 * warrants. Returns the new state plus how many levels were gained (for
 * celebration UI / achievement checks).
 */
export function applyXp(current: Progression, amount: number): LevelUpResult {
  if (amount < 0) throw new Error('XP amount must be non-negative');
  let { level, xp } = current;
  xp += amount;
  let levelsGained = 0;

  let need = xpForLevel(level);
  while (xp >= need) {
    xp -= need;
    level += 1;
    levelsGained += 1;
    need = xpForLevel(level);
  }

  return { level, xp, levelsGained, xpToNext: need };
}

/** Fraction (0..1) of the current level completed — for progress bars. */
export function levelProgress(p: Progression): number {
  const need = xpForLevel(p.level);
  return need === 0 ? 0 : Math.min(1, p.xp / need);
}
