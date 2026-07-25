import {
  Controller,
  Get,
  NotFoundException,
  Param,
  ParseIntPipe,
  Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { BattlePassService } from '../application/battle-pass.service';

@ApiTags('battle-pass')
@ApiBearerAuth()
@Controller('battle-pass')
export class BattlePassController {
  constructor(
    private readonly battlePass: BattlePassService,
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

  @Get('current')
  @ApiOperation({ summary: 'Active season, tiers, and my progress' })
  async current(@CurrentUser('userId') userId: string) {
    return this.battlePass.current(await this.characterId(userId));
  }

  @Post('claim/:tier')
  @ApiOperation({ summary: 'Claim the reward for a reached tier' })
  async claim(
    @CurrentUser('userId') userId: string,
    @Param('tier', ParseIntPipe) tier: number,
  ) {
    return this.battlePass.claim(await this.characterId(userId), tier);
  }
}
