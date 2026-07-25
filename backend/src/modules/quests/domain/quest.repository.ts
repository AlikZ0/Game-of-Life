import { Prisma, Quest, QuestCadence, QuestStatus } from '@prisma/client';

export const QUEST_REPOSITORY = Symbol('QUEST_REPOSITORY');

export interface QuestFilter {
  characterId: string;
  cadence?: QuestCadence;
  status?: QuestStatus;
}

/**
 * Persistence port for the Quest aggregate. The application layer depends on
 * this interface; `PrismaQuestRepository` provides the concrete adapter.
 */
export interface QuestRepository {
  findById(id: string): Promise<Quest | null>;
  findMany(filter: QuestFilter): Promise<Quest[]>;
  create(data: Prisma.QuestUncheckedCreateInput): Promise<Quest>;
  update(id: string, data: Prisma.QuestUpdateInput): Promise<Quest>;
  softDelete(id: string): Promise<void>;
}
