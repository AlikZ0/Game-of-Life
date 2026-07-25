import { Module } from '@nestjs/common';
import { CharacterService } from './application/character.service';
import { CHARACTER_REPOSITORY } from './domain/character.repository';
import { PrismaCharacterRepository } from './infrastructure/prisma-character.repository';
import { CharacterController } from './presentation/character.controller';

@Module({
  controllers: [CharacterController],
  providers: [
    CharacterService,
    { provide: CHARACTER_REPOSITORY, useClass: PrismaCharacterRepository },
  ],
  exports: [CharacterService],
})
export class CharacterModule {}
