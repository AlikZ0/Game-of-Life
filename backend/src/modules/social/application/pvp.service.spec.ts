import { PvpMetric, PvpStatus } from '@prisma/client';
import { PvpService } from './pvp.service';

describe('PvpService scoring & finalize', () => {
  function build(overrides?: {
    findMany?: unknown[];
    challenge?: Record<string, unknown> | null;
  }) {
    const prisma = {
      pvpChallenge: {
        findMany: jest.fn().mockResolvedValue(overrides?.findMany ?? []),
        findUnique: jest.fn().mockResolvedValue(overrides?.challenge ?? null),
        update: jest
          .fn()
          .mockImplementation(({ data }) => Promise.resolve({ ...data })),
      },
    };
    const characters = { awardRewards: jest.fn().mockResolvedValue({}) };
    // Lock is a pass-through in tests so the guarded cron body actually runs.
    const locks = {
      withLock: jest.fn((_k: string, _ttl: number, fn: () => unknown) => fn()),
    };
    const service = new PvpService(
      prisma as never,
      characters as never,
      locks as never,
    );
    return { service, prisma, characters };
  }

  // ── recordProgress ──────────────────────────────────────
  it('credits the challenger side for an active duel', async () => {
    const { service, prisma } = build({
      findMany: [{ id: 'p1', challengerId: 'c1', opponentId: 'c2' }],
    });
    await service.recordProgress('c1', PvpMetric.XP, 40);
    expect(prisma.pvpChallenge.update).toHaveBeenCalledWith({
      where: { id: 'p1' },
      data: { challengerScore: { increment: 40 } },
    });
  });

  it('credits the opponent side when the character is the opponent', async () => {
    const { service, prisma } = build({
      findMany: [{ id: 'p1', challengerId: 'c1', opponentId: 'c2' }],
    });
    await service.recordProgress('c2', PvpMetric.XP, 25);
    expect(prisma.pvpChallenge.update).toHaveBeenCalledWith({
      where: { id: 'p1' },
      data: { opponentScore: { increment: 25 } },
    });
  });

  it('ignores non-positive amounts', async () => {
    const { service, prisma } = build();
    await service.recordProgress('c1', PvpMetric.XP, 0);
    expect(prisma.pvpChallenge.findMany).not.toHaveBeenCalled();
  });

  // ── finalize ────────────────────────────────────────────
  it('finalizes with a winner and grants the reward', async () => {
    const { service, prisma, characters } = build({
      challenge: {
        id: 'p1',
        status: PvpStatus.ACTIVE,
        challengerId: 'c1',
        opponentId: 'c2',
        challengerScore: 100,
        opponentScore: 40,
      },
    });
    await service.finalize('p1');
    expect(prisma.pvpChallenge.update).toHaveBeenCalledWith({
      where: { id: 'p1' },
      data: { status: PvpStatus.FINISHED, winnerId: 'c1' },
    });
    expect(characters.awardRewards).toHaveBeenCalledWith(
      expect.objectContaining({ characterId: 'c1' }),
    );
  });

  it('finalizes a draw with no winner and no reward', async () => {
    const { service, characters } = build({
      challenge: {
        id: 'p1',
        status: PvpStatus.ACTIVE,
        challengerId: 'c1',
        opponentId: 'c2',
        challengerScore: 50,
        opponentScore: 50,
      },
    });
    await service.finalize('p1');
    expect(characters.awardRewards).not.toHaveBeenCalled();
  });

  it('is idempotent for an already-finished challenge', async () => {
    const { service, prisma, characters } = build({
      challenge: {
        id: 'p1',
        status: PvpStatus.FINISHED,
        challengerId: 'c1',
        opponentId: 'c2',
        challengerScore: 10,
        opponentScore: 0,
      },
    });
    await service.finalize('p1');
    expect(prisma.pvpChallenge.update).not.toHaveBeenCalled();
    expect(characters.awardRewards).not.toHaveBeenCalled();
  });
});
