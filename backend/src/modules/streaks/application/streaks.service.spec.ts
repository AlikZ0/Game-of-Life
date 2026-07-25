import { Test } from '@nestjs/testing';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { StreaksService } from './streaks.service';

/**
 * Focused unit test for the day-math branches of the streak engine. PrismaService
 * is fully mocked so no database is involved.
 */
describe('StreaksService', () => {
  let service: StreaksService;
  let streak: Record<string, unknown>;
  let findUnique: jest.Mock;
  let update: jest.Mock;
  let create: jest.Mock;

  const NOW = new Date('2026-07-25T12:00:00.000Z'); // day = 2026-07-25

  beforeEach(async () => {
    findUnique = jest.fn(async () => streak);
    // update returns the record merged with the written data
    update = jest.fn(async ({ data }: { data: Record<string, unknown> }) => ({
      ...streak,
      ...data,
    }));
    create = jest.fn(async ({ data }: { data: Record<string, unknown> }) => ({
      current: 0,
      longest: 0,
      freezeCount: 0,
      lastActiveDay: null,
      ...data,
    }));

    const prismaMock = {
      streak: { findUnique, update, create },
    } as unknown as PrismaService;

    const moduleRef = await Test.createTestingModule({
      providers: [
        StreaksService,
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    service = moduleRef.get(StreaksService);
  });

  it('increments the streak on a consecutive day', async () => {
    streak = {
      current: 4,
      longest: 4,
      freezeCount: 0,
      lastActiveDay: '2026-07-24', // yesterday
    };

    const result = await service.registerActivity('char-1', NOW);

    expect(update).toHaveBeenCalledTimes(1);
    expect(update.mock.calls[0][0].data).toMatchObject({
      current: 5,
      longest: 5,
      lastActiveDay: '2026-07-25',
    });
    expect(result.current).toBe(5);
  });

  it('does not double-count activity on the same day', async () => {
    streak = {
      current: 4,
      longest: 6,
      freezeCount: 0,
      lastActiveDay: '2026-07-25', // already today
    };

    const result = await service.registerActivity('char-1', NOW);

    expect(update).not.toHaveBeenCalled();
    expect(result.current).toBe(4);
  });

  it('resets the streak to 1 after a multi-day gap', async () => {
    streak = {
      current: 9,
      longest: 12,
      freezeCount: 0,
      lastActiveDay: '2026-07-20', // 5 days ago, no freezes to spend
    };

    const result = await service.registerActivity('char-1', NOW);

    expect(update).toHaveBeenCalledTimes(1);
    expect(update.mock.calls[0][0].data).toMatchObject({
      current: 1,
      lastActiveDay: '2026-07-25',
    });
    expect(result.current).toBe(1);
  });

  it('starts a streak at 1 from a fresh (null) record', async () => {
    streak = {
      current: 0,
      longest: 0,
      freezeCount: 0,
      lastActiveDay: null,
    };

    const result = await service.registerActivity('char-1', NOW);

    expect(result.current).toBe(1);
    expect(update.mock.calls[0][0].data).toMatchObject({ current: 1 });
  });
});
