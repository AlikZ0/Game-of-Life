import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import configuration from './config/configuration';
import { validateEnv } from './config/env.validation';
import { JwtAuthGuard } from './modules/auth/infrastructure/jwt-auth.guard';
import { PrismaModule } from './infra/prisma/prisma.module';

import { AchievementsModule } from './modules/achievements/achievements.module';
import { AiCoachModule } from './modules/ai-coach/ai-coach.module';
import { AuthModule } from './modules/auth/auth.module';
import { BossesModule } from './modules/bosses/bosses.module';
import { CharacterModule } from './modules/character/character.module';
import { EconomyModule } from './modules/economy/economy.module';
import { HealthModule } from './modules/health/health.module';
import { MonetizationModule } from './modules/monetization/monetization.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { QuestsModule } from './modules/quests/quests.module';
import { RealtimeModule } from './modules/realtime/realtime.module';
import { SkillsModule } from './modules/skills/skills.module';
import { SocialModule } from './modules/social/social.module';
import { StatsModule } from './modules/stats/stats.module';
import { StreaksModule } from './modules/streaks/streaks.module';

@Module({
  imports: [
    // ── Platform ──────────────────────────────────────────
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      validate: validateEnv,
    }),
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        {
          ttl: config.get<number>('throttle.ttl', 60) * 1000,
          limit: config.get<number>('throttle.limit', 120),
        },
      ],
    }),
    ScheduleModule.forRoot(),
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        connection: {
          host: config.get<string>('redis.host', 'localhost'),
          port: config.get<number>('redis.port', 6379),
        },
      }),
    }),
    PrismaModule,

    // ── Bounded contexts ─────────────────────────────────
    AuthModule,
    CharacterModule,
    SkillsModule,
    QuestsModule,
    BossesModule,
    StreaksModule,
    AchievementsModule,
    EconomyModule,
    StatsModule,
    AiCoachModule,
    SocialModule,
    NotificationsModule,
    MonetizationModule,
    RealtimeModule,
    HealthModule,
  ],
  providers: [
    // Global JWT authentication (routes opt out with @Public())
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    // Global rate limiting
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
