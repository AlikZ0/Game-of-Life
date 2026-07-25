import { Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { AchievementsService } from '../application/achievements.service';

@ApiTags('achievements')
@ApiBearerAuth()
@Controller('achievements')
export class AchievementsController {
  constructor(
    private readonly achievements: AchievementsService,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'List all achievements with unlock status' })
  list(@CurrentUser('userId') userId: string) {
    return this.achievements.list(userId);
  }

  @Post('evaluate')
  @ApiOperation({
    summary: 'Re-check and unlock any newly earned achievements',
  })
  async evaluate(@CurrentUser('characterId') characterId: string) {
    return this.achievements.evaluate(characterId);
  }
}
