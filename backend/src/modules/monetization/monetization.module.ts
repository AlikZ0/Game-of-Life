import { Module } from '@nestjs/common';
import { CharacterModule } from '../character/character.module';
import { BattlePassService } from './application/battle-pass.service';
import { SubscriptionService } from './application/subscription.service';
import { BattlePassController } from './presentation/battle-pass.controller';
import { SubscriptionController } from './presentation/subscription.controller';

@Module({
  imports: [CharacterModule],
  controllers: [BattlePassController, SubscriptionController],
  providers: [BattlePassService, SubscriptionService],
  exports: [BattlePassService, SubscriptionService],
})
export class MonetizationModule {}
