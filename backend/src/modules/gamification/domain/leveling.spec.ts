import {
  applyXp,
  cumulativeXpForLevel,
  levelProgress,
  xpForLevel,
} from './leveling';

describe('leveling', () => {
  it('produces a strictly increasing, super-linear curve', () => {
    expect(xpForLevel(1)).toBe(100);
    expect(xpForLevel(2)).toBeGreaterThan(xpForLevel(1));
    expect(xpForLevel(10)).toBeGreaterThan(xpForLevel(9));
    // super-linear: gap grows
    expect(xpForLevel(10) - xpForLevel(9)).toBeGreaterThan(
      xpForLevel(2) - xpForLevel(1),
    );
  });

  it('cumulative XP is the sum of per-level requirements', () => {
    const expected = xpForLevel(1) + xpForLevel(2) + xpForLevel(3);
    expect(cumulativeXpForLevel(4)).toBe(expected);
  });

  it('applies XP without leveling when below threshold', () => {
    const r = applyXp({ level: 1, xp: 0 }, 50);
    expect(r.level).toBe(1);
    expect(r.xp).toBe(50);
    expect(r.levelsGained).toBe(0);
  });

  it('rolls over a single level exactly at threshold', () => {
    const r = applyXp({ level: 1, xp: 0 }, xpForLevel(1));
    expect(r.level).toBe(2);
    expect(r.xp).toBe(0);
    expect(r.levelsGained).toBe(1);
  });

  it('rolls over multiple levels in one gain', () => {
    const big = xpForLevel(1) + xpForLevel(2) + xpForLevel(3) + 10;
    const r = applyXp({ level: 1, xp: 0 }, big);
    expect(r.level).toBe(4);
    expect(r.xp).toBe(10);
    expect(r.levelsGained).toBe(3);
  });

  it('rejects negative XP', () => {
    expect(() => applyXp({ level: 1, xp: 0 }, -5)).toThrow();
  });

  it('reports progress as a 0..1 fraction', () => {
    const p = levelProgress({ level: 2, xp: Math.floor(xpForLevel(2) / 2) });
    expect(p).toBeGreaterThan(0.45);
    expect(p).toBeLessThan(0.55);
  });
});
