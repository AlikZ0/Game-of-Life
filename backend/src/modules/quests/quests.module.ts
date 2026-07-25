import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { BossesModule } from '../bosses/bosses.module';
import { CharacterModule } from '../character/character.module';
import { GAMIFICATION_QUEUE } from '../gamification/gamification.constants';
import { MonetizationModule } from '../monetization/monetization.module';
import { RealtimeModule } from '../realtime/realtime.module';
import { SocialModule } from '../social/social.module';
import { StreaksModule } from '../streaks/streaks.module';
import { QuestsService } from './application/quests.service';
import { QUEST_REPOSITORY } from './domain/quest.repository';
import { PrismaQuestRepository } from './infrastructure/prisma-quest.repository';
import { QuestsController } from './presentation/quests.controller';

@Module({
  imports: [
    CharacterModule,
    BossesModule,
    StreaksModule,
    RealtimeModule,
    SocialModule,
    MonetizationModule,
    BullModule.registerQueue({ name: GAMIFICATION_QUEUE }),
  ],
  controllers: [QuestsController],
  providers: [
    QuestsService,
    { provide: QUEST_REPOSITORY, useClass: PrismaQuestRepository },
  ],
  exports: [QuestsService],
})
export class QuestsModule {}
