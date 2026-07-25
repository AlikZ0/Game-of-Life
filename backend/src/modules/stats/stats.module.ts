import { Module } from '@nestjs/common';
import { StatsService } from './application/stats.service';
import { StatsController } from './presentation/stats.controller';

@Module({
  controllers: [StatsController],
  providers: [StatsService],
  exports: [StatsService],
})
export class StatsModule {}
