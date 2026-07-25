import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { SkillsService } from '../application/skills.service';

@ApiTags('skills')
@ApiBearerAuth()
@Controller('skills')
export class SkillsController {
  constructor(private readonly skills: SkillsService) {}

  @Get()
  @ApiOperation({ summary: 'List the character’s skills with levels & progress' })
  list(@CurrentUser('userId') userId: string) {
    return this.skills.list(userId);
  }

  @Get('heatmap')
  @ApiOperation({ summary: 'Daily skill-XP heatmap for the last N days' })
  heatmap(
    @CurrentUser('userId') userId: string,
    @Query('days') days?: string,
  ) {
    return this.skills.heatmap(userId, days ? Number(days) : undefined);
  }

  @Get(':key/history')
  @ApiOperation({ summary: 'Recent XP events for a single skill' })
  history(
    @CurrentUser('userId') userId: string,
    @Param('key') key: string,
  ) {
    return this.skills.history(userId, key);
  }
}
