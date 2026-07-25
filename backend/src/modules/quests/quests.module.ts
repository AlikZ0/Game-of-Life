import { Module } from '@nestjs/common';
import { BossesModule } from '../bosses/bosses.module';
import { CharacterModule } from '../character/character.module';
import { StreaksModule } from '../streaks/streaks.module';
import { QuestsService } from './application/quests.service';
import { QUEST_REPOSITORY } from './domain/quest.repository';
import { PrismaQuestRepository } from './infrastructure/prisma-quest.repository';
import { QuestsController } from './presentation/quests.controller';

@Module({
  imports: [CharacterModule, BossesModule, StreaksModule],
  controllers: [QuestsController],
  providers: [
    QuestsService,
    { provide: QUEST_REPOSITORY, useClass: PrismaQuestRepository },
  ],
  exports: [QuestsService],
})
export class QuestsModule {}
