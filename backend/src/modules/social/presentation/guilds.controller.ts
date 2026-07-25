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
import { GuildsService } from '../application/guilds.service';
import {
  CreateGuildDto,
  CreateGuildMissionDto,
  GuildMessageDto,
} from '../application/dto/guild.dto';

@ApiTags('guilds')
@ApiBearerAuth()
@Controller('guilds')
export class GuildsController {
  constructor(
    private readonly guilds: GuildsService,
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
  @ApiOperation({ summary: 'Create a guild (creator becomes LEADER)' })
  async create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateGuildDto,
  ) {
    return this.guilds.create(await this.characterId(userId), dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Guild details with members' })
  async get(@Param('id') id: string) {
    return this.guilds.get(id);
  }

  @Post(':id/join')
  @ApiOperation({ summary: 'Join a guild' })
  async join(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ) {
    return this.guilds.join(await this.characterId(userId), id);
  }

  @Post(':id/leave')
  @ApiOperation({ summary: 'Leave a guild' })
  async leave(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ) {
    return this.guilds.leave(await this.characterId(userId), id);
  }

  @Get(':id/leaderboard')
  @ApiOperation({ summary: 'Members ranked by weekly XP' })
  async leaderboard(@Param('id') id: string) {
    return this.guilds.leaderboard(id);
  }

  @Get(':id/messages')
  @ApiOperation({ summary: 'Recent guild chat messages' })
  async messages(@Param('id') id: string) {
    return this.guilds.messages(id);
  }

  @Post(':id/messages')
  @ApiOperation({ summary: 'Post a message to guild chat' })
  async postMessage(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
    @Body() dto: GuildMessageDto,
  ) {
    return this.guilds.postMessage(await this.characterId(userId), id, dto);
  }

  @Get(':id/missions')
  @ApiOperation({ summary: 'List guild missions' })
  async missions(@Param('id') id: string) {
    return this.guilds.listMissions(id);
  }

  @Post(':id/missions')
  @ApiOperation({ summary: 'Create a guild mission (leader only)' })
  async createMission(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
    @Body() dto: CreateGuildMissionDto,
  ) {
    return this.guilds.createMission(await this.characterId(userId), id, dto);
  }
}
