import { Module } from '@nestjs/common';
import { StreaksService } from './application/streaks.service';
import { StreaksController } from './presentation/streaks.controller';

@Module({
  controllers: [StreaksController],
  providers: [StreaksService],
  exports: [StreaksService],
})
export class StreaksModule {}
