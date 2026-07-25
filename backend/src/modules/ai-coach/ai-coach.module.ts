import { Module } from '@nestjs/common';
import { MonetizationModule } from '../monetization/monetization.module';
import { StatsModule } from '../stats/stats.module';
import { AiCoachService } from './application/ai-coach.service';
import { AiCoachController } from './presentation/ai-coach.controller';

@Module({
  imports: [StatsModule, MonetizationModule],
  controllers: [AiCoachController],
  providers: [AiCoachService],
})
export class AiCoachModule {}
