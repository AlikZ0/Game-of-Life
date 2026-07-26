import { PaginationQueryDto } from '../../../common/dto/pagination.dto';
import { EconomyService } from './economy.service';

describe('EconomyService.ledger', () => {
  function build(rows: unknown[], total: number) {
    const prisma = {
      goldLedgerEntry: {
        findMany: jest.fn().mockResolvedValue(rows),
        count: jest.fn().mockResolvedValue(total),
      },
    };
    return { service: new EconomyService(prisma as never), prisma };
  }

  const query = (page: number, limit: number) =>
    Object.assign(new PaginationQueryDto(), { page, limit });

  it('returns newest-first, paginated entries with meta', async () => {
    const { service, prisma } = build(
      [{ id: 'g1', delta: 15, balance: 15, reason: 'QUEST_REWARD' }],
      1,
    );

    const result = await service.ledger('c1', query(1, 20));

    expect(prisma.goldLedgerEntry.findMany).toHaveBeenCalledWith({
      where: { characterId: 'c1' },
      orderBy: { createdAt: 'desc' },
      skip: 0,
      take: 20,
    });
    expect(result.items).toHaveLength(1);
    expect(result.meta).toMatchObject({
      page: 1,
      limit: 20,
      total: 1,
      totalPages: 1,
    });
  });

  it('applies the page offset', async () => {
    const { service, prisma } = build([], 45);
    const result = await service.ledger('c1', query(3, 20));
    expect(prisma.goldLedgerEntry.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ skip: 40, take: 20 }),
    );
    expect(result.meta.totalPages).toBe(3);
  });
});
