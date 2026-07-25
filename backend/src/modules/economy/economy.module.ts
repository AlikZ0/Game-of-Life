import { Module } from '@nestjs/common';
import { EconomyService } from './application/economy.service';
import { EconomyController } from './presentation/economy.controller';

@Module({
  controllers: [EconomyController],
  providers: [EconomyService],
  exports: [EconomyService],
})
export class EconomyModule {}
