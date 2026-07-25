import { Module } from '@nestjs/common';
import { CharacterModule } from '../character/character.module';
import { AchievementsService } from './application/achievements.service';
import { AchievementsController } from './presentation/achievements.controller';

@Module({
  imports: [CharacterModule],
  controllers: [AchievementsController],
  providers: [AchievementsService],
  exports: [AchievementsService],
})
export class AchievementsModule {}
