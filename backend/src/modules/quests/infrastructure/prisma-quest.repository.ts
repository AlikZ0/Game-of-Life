import { Injectable } from '@nestjs/common';
import { Prisma, Quest } from '@prisma/client';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { QuestFilter, QuestRepository } from '../domain/quest.repository';

@Injectable()
export class PrismaQuestRepository implements QuestRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<Quest | null> {
    return this.prisma.quest.findUnique({ where: { id } });
  }

  findMany(filter: QuestFilter): Promise<Quest[]> {
    return this.prisma.quest.findMany({
      where: {
        characterId: filter.characterId,
        cadence: filter.cadence,
        status: filter.status ?? 'ACTIVE',
      },
      orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
    });
  }

  create(data: Prisma.QuestUncheckedCreateInput): Promise<Quest> {
    return this.prisma.quest.create({ data });
  }

  update(id: string, data: Prisma.QuestUpdateInput): Promise<Quest> {
    return this.prisma.quest.update({ where: { id }, data });
  }

  async softDelete(id: string): Promise<void> {
    await this.prisma.quest.update({
      where: { id },
      data: { status: 'ARCHIVED', archivedAt: new Date() },
    });
  }
}
