import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import configuration from '../config/configuration';
import { validateEnv } from '../config/env.validation';
import { PrismaModule } from '../infra/prisma/prisma.module';
import { AchievementsModule } from '../modules/achievements/achievements.module';
import { CharacterModule } from '../modules/character/character.module';
import { GAMIFICATION_QUEUE } from '../modules/gamification/gamification.constants';
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
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        connection: {
          host: config.get<string>('redis.host', 'localhost'),
          port: config.get<number>('redis.port', 6379),
        },
      }),
    }),
    BullModule.registerQueue({ name: GAMIFICATION_QUEUE }),
    PrismaModule,
    CharacterModule,
    AchievementsModule,
    NotificationsModule,
  ],
  providers: [GamificationProcessor],
})
export class WorkerModule {}
