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
import { PvpService } from '../application/pvp.service';
import { CreatePvpChallengeDto } from '../application/dto/pvp.dto';

@ApiTags('pvp')
@ApiBearerAuth()
@Controller('pvp')
export class PvpController {
  constructor(
    private readonly pvp: PvpService,
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
  @ApiOperation({ summary: 'Challenge another character to a 7-day duel' })
  async create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreatePvpChallengeDto,
  ) {
    return this.pvp.create(await this.characterId(userId), dto);
  }

  @Post(':id/accept')
  @ApiOperation({ summary: 'Accept a pending challenge (opponent only)' })
  async accept(@CurrentUser('userId') userId: string, @Param('id') id: string) {
    return this.pvp.accept(await this.characterId(userId), id);
  }

  @Get()
  @ApiOperation({ summary: 'List my challenges (as challenger or opponent)' })
  async listMine(@CurrentUser('userId') userId: string) {
    return this.pvp.listMine(await this.characterId(userId));
  }

  @Get(':id/standings')
  @ApiOperation({ summary: 'Challenge standings (winner shown when FINISHED)' })
  async standings(@Param('id') id: string) {
    return this.pvp.standings(id);
  }
}
