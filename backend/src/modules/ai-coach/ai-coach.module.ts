import { Module } from '@nestjs/common';
import { StatsModule } from '../stats/stats.module';
import { AiCoachService } from './application/ai-coach.service';
import { AiCoachController } from './presentation/ai-coach.controller';

@Module({
  imports: [StatsModule],
  controllers: [AiCoachController],
  providers: [AiCoachService],
})
export class AiCoachModule {}
