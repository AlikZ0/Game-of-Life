import { Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { AiCoachService } from '../application/ai-coach.service';

@ApiTags('ai-coach')
@ApiBearerAuth()
@Controller('ai-coach')
export class AiCoachController {
  constructor(private readonly coach: AiCoachService) {}

  @Get('analyze')
  @ApiOperation({ summary: 'Analyze habits, weak areas and predict progress' })
  analyze(@CurrentUser('userId') userId: string) {
    return this.coach.analyze(userId);
  }

  @Post('generate-quests')
  @ApiOperation({ summary: 'Generate personalised quest suggestions' })
  async generate(@CurrentUser('userId') userId: string) {
    const analysis = await this.coach.analyze(userId);
    return analysis.suggestedQuests;
  }
}
