import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { BossesService } from '../application/bosses.service';
import { BossResponseDto, CreateBossDto } from '../application/dto/boss.dto';

@ApiTags('bosses')
@ApiBearerAuth()
@Controller('bosses')
export class BossesController {
  constructor(
    private readonly bosses: BossesService,
    private readonly prisma: PrismaService,
  ) {}

  private async characterId(userId: string): Promise<string> {
    const c = await this.prisma.character.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!c) throw new NotFoundException('Character not found');
    return c.id;
  }

  @Post()
  @ApiOperation({ summary: 'Create a boss from a large goal' })
  async create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateBossDto,
  ): Promise<BossResponseDto> {
    return this.bosses.create(await this.characterId(userId), dto);
  }

  @Get()
  @ApiOperation({ summary: 'List the character’s bosses' })
  async list(@CurrentUser('userId') userId: string) {
    return this.bosses.list(await this.characterId(userId));
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a single boss with HP + linked quest count' })
  async get(@CurrentUser('userId') userId: string, @Param('id') id: string) {
    return this.bosses.get(await this.characterId(userId), id);
  }

  @Get(':id/quests')
  @ApiOperation({ summary: 'ACTIVE quests attacking this boss' })
  async quests(@CurrentUser('userId') userId: string, @Param('id') id: string) {
    return this.bosses.linkedQuests(await this.characterId(userId), id);
  }
}
