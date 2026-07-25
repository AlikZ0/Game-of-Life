import { Module } from '@nestjs/common';
import { SkillsService } from './application/skills.service';
import { SkillsController } from './presentation/skills.controller';

@Module({
  controllers: [SkillsController],
  providers: [SkillsService],
  exports: [SkillsService],
})
export class SkillsModule {}
