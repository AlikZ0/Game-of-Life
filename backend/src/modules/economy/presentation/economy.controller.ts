import {
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { EconomyService } from '../application/economy.service';
import { CreateShopRewardDto } from '../application/dto/economy.dto';

@ApiTags('economy')
@ApiBearerAuth()
@Controller()
export class EconomyController {
  constructor(
    private readonly economy: EconomyService,
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

  @Get('shop')
  @ApiOperation({ summary: 'List the user’s custom shop rewards' })
  async listShop(@CurrentUser('userId') userId: string) {
    return this.economy.listShop(await this.characterId(userId));
  }

  @Post('shop')
  @ApiOperation({ summary: 'Create a real-life reward redeemable with gold' })
  async createReward(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateShopRewardDto,
  ) {
    return this.economy.createReward(await this.characterId(userId), dto);
  }

  @Delete('shop/:id')
  @ApiOperation({ summary: 'Deactivate a shop reward' })
  async deleteReward(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ) {
    await this.economy.deleteReward(await this.characterId(userId), id);
    return { success: true };
  }

  @Post('shop/:id/redeem')
  @ApiOperation({ summary: 'Spend gold to redeem a reward → inventory coupon' })
  async redeem(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ) {
    return this.economy.redeem(await this.characterId(userId), id);
  }

  @Get('inventory')
  @ApiOperation({ summary: 'List owned cosmetics, titles, coupons and items' })
  async inventory(@CurrentUser('userId') userId: string) {
    return this.economy.listInventory(await this.characterId(userId));
  }

  @Post('inventory/:id/equip')
  @ApiOperation({ summary: 'Equip / unequip a cosmetic item' })
  async equip(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
    @Body('equipped') equipped: boolean,
  ) {
    return this.economy.equip(await this.characterId(userId), id, equipped ?? true);
  }
}
