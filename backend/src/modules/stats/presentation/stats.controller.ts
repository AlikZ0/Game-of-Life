import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { StatsService } from '../application/stats.service';

@ApiTags('stats')
@ApiBearerAuth()
@Controller('stats')
export class StatsController {
  constructor(private readonly stats: StatsService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Headline statistics dashboard' })
  dashboard(@CurrentUser('userId') userId: string) {
    return this.stats.dashboard(userId);
  }

  @Get('xp-series')
  @ApiOperation({ summary: 'Daily XP time-series for charts' })
  xpSeries(
    @CurrentUser('userId') userId: string,
    @Query('days') days?: string,
  ) {
    return this.stats.xpSeries(userId, days ? Number(days) : undefined);
  }

  @Get('life-balance')
  @ApiOperation({ summary: 'Per-skill XP share + neglected-area flags' })
  lifeBalance(@CurrentUser('userId') userId: string) {
    return this.stats.lifeBalance(userId);
  }
}
