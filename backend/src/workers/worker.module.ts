import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from '../config/configuration';
import { validateEnv } from '../config/env.validation';
import { PrismaModule } from '../infra/prisma/prisma.module';
import { AchievementsModule } from '../modules/achievements/achievements.module';
import { CharacterModule } from '../modules/character/character.module';
import { NotificationsModule } from '../modules/notifications/notifications.module';
import { GamificationProcessor } from './processors/gamification.processor';

/**
 * Root module for the standalone worker process (see src/worker.ts).
 * Hosts BullMQ processors that handle asynchronous side-effects of gameplay:
 * achievement evaluation, streak reminders, push notifications, leaderboard
 * recomputation — keeping the request path fast.
 */
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      validate: validateEnv,
    }),
    PrismaModule,
    CharacterModule,
    AchievementsModule,
    NotificationsModule,
  ],
  providers: [GamificationProcessor],
})
export class WorkerModule {}
