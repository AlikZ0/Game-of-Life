import { Module } from '@nestjs/common';
import { CharacterModule } from '../character/character.module';
import { GuildsService } from './application/guilds.service';
import { PvpService } from './application/pvp.service';
import { GuildsController } from './presentation/guilds.controller';
import { PvpController } from './presentation/pvp.controller';

@Module({
  imports: [CharacterModule],
  controllers: [GuildsController, PvpController],
  providers: [GuildsService, PvpService],
  exports: [GuildsService, PvpService],
})
export class SocialModule {}
