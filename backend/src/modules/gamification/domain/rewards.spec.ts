import { computeReward, streakMultiplier } from './rewards';

describe('rewards', () => {
  const base = {
    baseXp: 100,
    baseGold: 50,
    baseEnergyCost: 10,
    baseDamage: 20,
  };

  it('scales rewards up for harder difficulties', () => {
    const medium = computeReward({ ...base, difficulty: 'MEDIUM' });
    const epic = computeReward({ ...base, difficulty: 'EPIC' });
    expect(epic.xp).toBeGreaterThan(medium.xp);
    expect(epic.gold).toBeGreaterThan(medium.gold);
    expect(epic.damage).toBeGreaterThan(medium.damage);
  });

  it('scales rewards down for trivial difficulty', () => {
    const trivial = computeReward({ ...base, difficulty: 'TRIVIAL' });
    expect(trivial.xp).toBe(50); // 100 * 0.5
  });

  it('applies a streak multiplier on top of difficulty', () => {
    const plain = computeReward({ ...base, difficulty: 'MEDIUM' });
    const streaked = computeReward({
      ...base,
      difficulty: 'MEDIUM',
      streakMultiplier: 1.3,
    });
    expect(streaked.xp).toBe(Math.round(plain.xp * 1.3));
  });

  it('returns a capped, monotonic streak multiplier', () => {
    expect(streakMultiplier(0)).toBe(1);
    expect(streakMultiplier(3)).toBeGreaterThan(streakMultiplier(0));
    expect(streakMultiplier(7)).toBeGreaterThan(streakMultiplier(3));
    expect(streakMultiplier(100)).toBe(1.5);
    expect(streakMultiplier(10_000)).toBe(1.5); // capped
  });
});
