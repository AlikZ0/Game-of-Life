import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import { QuestCadence } from '@prisma/client';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { QuestsService } from '../application/quests.service';
import {
  CreateQuestDto,
  QuestCompletionResultDto,
  QuestResponseDto,
  UpdateQuestDto,
} from '../application/dto/quest.dto';

@ApiTags('quests')
@ApiBearerAuth()
@Controller('quests')
export class QuestsController {
  constructor(private readonly quests: QuestsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a quest' })
  create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateQuestDto,
  ): Promise<QuestResponseDto> {
    return this.quests.create(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List quests, optionally filtered by cadence' })
  @ApiQuery({ name: 'cadence', enum: QuestCadence, required: false })
  list(
    @CurrentUser('userId') userId: string,
    @Query('cadence') cadence?: QuestCadence,
  ): Promise<QuestResponseDto[]> {
    return this.quests.list(userId, cadence);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Edit a quest' })
  update(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateQuestDto,
  ): Promise<QuestResponseDto> {
    return this.quests.update(userId, id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  @ApiOperation({ summary: 'Archive (soft-delete) a quest' })
  async remove(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ): Promise<void> {
    await this.quests.remove(userId, id);
  }

  @Post(':id/complete')
  @ApiOperation({ summary: 'Complete a quest and collect rewards' })
  complete(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ): Promise<QuestCompletionResultDto> {
    return this.quests.complete(userId, id);
  }
}
