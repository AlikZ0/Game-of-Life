import { Controller, Get, NotFoundException } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { StreaksService } from '../application/streaks.service';

@ApiTags('streaks')
@ApiBearerAuth()
@Controller('streaks')
export class StreaksController {
  constructor(
    private readonly streaks: StreaksService,
    private readonly prisma: PrismaService,
  ) {}

  @Get('me')
  @ApiOperation({ summary: 'Current streak, longest streak, and freezes' })
  async me(@CurrentUser('userId') userId: string) {
    const character = await this.prisma.character.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!character) throw new NotFoundException('Character not found');
    return this.streaks.get(character.id);
  }
}
