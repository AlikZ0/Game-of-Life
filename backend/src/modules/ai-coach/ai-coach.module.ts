import { Module } from '@nestjs/common';
import { MonetizationModule } from '../monetization/monetization.module';
import { StatsModule } from '../stats/stats.module';
import { AiCoachService } from './application/ai-coach.service';
import { LlmClient } from './infrastructure/llm-client';
import { AiCoachController } from './presentation/ai-coach.controller';

@Module({
  imports: [StatsModule, MonetizationModule],
  controllers: [AiCoachController],
  providers: [AiCoachService, LlmClient],
})
export class AiCoachModule {}
