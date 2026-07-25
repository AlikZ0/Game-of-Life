import { Module } from '@nestjs/common';
import { CharacterModule } from '../character/character.module';
import { BossesService } from './application/bosses.service';
import { BossesController } from './presentation/bosses.controller';

@Module({
  imports: [CharacterModule],
  controllers: [BossesController],
  providers: [BossesService],
  exports: [BossesService],
})
export class BossesModule {}
