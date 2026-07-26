import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { BossesService } from './bosses.service';

describe('BossesService.linkedQuests', () => {
  function build(opts: {
    boss?: { characterId: string } | null;
    quests?: Array<Record<string, unknown>>;
    completions?: Record<string, unknown>;
  }) {
    const prisma = {
      boss: {
        findUnique: jest.fn().mockResolvedValue(opts.boss ?? null),
      },
      quest: {
        findMany: jest.fn().mockResolvedValue(opts.quests ?? []),
      },
      questCompletion: {
        findUnique: jest.fn().mockImplementation(({ where }) => {
          const key = where.questId_periodKey.questId;
          return Promise.resolve(opts.completions?.[key] ?? null);
        }),
      },
    };
    const characters = {} as never;
    return {
      service: new BossesService(prisma as never, characters),
      prisma,
    };
  }

  it('maps ACTIVE quests with damage and completion state', async () => {
    const { service, prisma } = build({
      boss: { characterId: 'c1' },
      quests: [
        {
          id: 'q1',
          title: 'Read a chapter',
          difficulty: 'MEDIUM',
          damage: 20,
          cadence: 'DAILY',
        },
        {
          id: 'q2',
          title: 'Ship a feature',
          difficulty: 'HARD',
          damage: 40,
          cadence: 'DAILY',
        },
      ],
      completions: { q1: { id: 'done' } },
    });

    const result = await service.linkedQuests('c1', 'b1');

    expect(prisma.quest.findMany).toHaveBeenCalledWith({
      where: { bossId: 'b1', characterId: 'c1', status: 'ACTIVE' },
      orderBy: { createdAt: 'desc' },
    });
    expect(result).toEqual([
      {
        id: 'q1',
        title: 'Read a chapter',
        difficulty: 'MEDIUM',
        damage: 20,
        completedThisPeriod: true,
      },
      {
        id: 'q2',
        title: 'Ship a feature',
        difficulty: 'HARD',
        damage: 40,
        completedThisPeriod: false,
      },
    ]);
  });

  it('returns an empty list when no quests are linked', async () => {
    const { service } = build({ boss: { characterId: 'c1' }, quests: [] });
    await expect(service.linkedQuests('c1', 'b1')).resolves.toEqual([]);
  });

  it('throws NotFound when the boss does not exist', async () => {
    const { service } = build({ boss: null });
    await expect(service.linkedQuests('c1', 'missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('throws Forbidden when the boss belongs to another character', async () => {
    const { service } = build({ boss: { characterId: 'other' } });
    await expect(service.linkedQuests('c1', 'b1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
