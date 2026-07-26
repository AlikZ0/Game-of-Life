import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { GoldLedgerEntry, ItemType, LedgerReason } from '@prisma/client';
import {
  PaginatedResult,
  PaginationQueryDto,
  paginate,
} from '../../../common/dto/pagination.dto';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { CreateShopRewardDto } from './dto/economy.dto';

@Injectable()
export class EconomyService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Shop ────────────────────────────────────────────────
  listShop(characterId: string) {
    return this.prisma.shopReward.findMany({
      where: { characterId, isActive: true },
      orderBy: { goldCost: 'asc' },
    });
  }

  createReward(characterId: string, dto: CreateShopRewardDto) {
    return this.prisma.shopReward.create({
      data: {
        characterId,
        title: dto.title,
        description: dto.description,
        goldCost: dto.goldCost,
        stock: dto.stock ?? null,
      },
    });
  }

  async deleteReward(characterId: string, id: string) {
    const reward = await this.prisma.shopReward.findUnique({ where: { id } });
    if (!reward || reward.characterId !== characterId) {
      throw new NotFoundException('Reward not found');
    }
    await this.prisma.shopReward.update({
      where: { id },
      data: { isActive: false },
    });
  }

  /**
   * Redeem a shop reward: atomically debit gold (with a ledger entry), decrement
   * stock, and mint a coupon into the inventory. Rejects if the character can't
   * afford it or the reward is out of stock.
   */
  async redeem(characterId: string, rewardId: string) {
    return this.prisma.$transaction(async (tx) => {
      const [reward, character] = await Promise.all([
        tx.shopReward.findUnique({ where: { id: rewardId } }),
        tx.character.findUnique({ where: { id: characterId } }),
      ]);
      if (!reward || reward.characterId !== characterId || !reward.isActive) {
        throw new NotFoundException('Reward not found');
      }
      if (!character) throw new NotFoundException('Character not found');
      if (reward.stock !== null && reward.stock <= 0) {
        throw new BadRequestException('Reward out of stock');
      }
      if (character.gold < reward.goldCost) {
        throw new BadRequestException('Not enough gold');
      }

      const newGold = character.gold - reward.goldCost;
      await tx.character.update({
        where: { id: characterId },
        data: { gold: newGold },
      });
      await tx.goldLedgerEntry.create({
        data: {
          characterId,
          delta: -reward.goldCost,
          balance: newGold,
          reason: LedgerReason.SHOP_PURCHASE,
          refId: reward.id,
        },
      });
      await tx.shopReward.update({
        where: { id: reward.id },
        data: {
          timesRedeemed: { increment: 1 },
          stock: reward.stock !== null ? { decrement: 1 } : undefined,
        },
      });
      const coupon = await tx.inventoryItem.create({
        data: {
          characterId,
          itemType: ItemType.REWARD_COUPON,
          refKey: reward.id,
          name: reward.title,
          metadata: { redeemedAt: new Date().toISOString() },
        },
      });
      return { coupon, goldBalance: newGold };
    });
  }

  // ── Inventory ───────────────────────────────────────────
  listInventory(characterId: string) {
    return this.prisma.inventoryItem.findMany({
      where: { characterId },
      orderBy: { acquiredAt: 'desc' },
    });
  }

  async equip(characterId: string, itemId: string, equipped: boolean) {
    const item = await this.prisma.inventoryItem.findUnique({
      where: { id: itemId },
    });
    if (!item || item.characterId !== characterId) {
      throw new NotFoundException('Item not found');
    }
    return this.prisma.inventoryItem.update({
      where: { id: itemId },
      data: { equipped },
    });
  }

  // ── Gold ledger ─────────────────────────────────────────
  /** Paginated, newest-first history of the character's gold movements. */
  async ledger(
    characterId: string,
    query: PaginationQueryDto,
  ): Promise<PaginatedResult<GoldLedgerEntry>> {
    const [items, total] = await Promise.all([
      this.prisma.goldLedgerEntry.findMany({
        where: { characterId },
        orderBy: { createdAt: 'desc' },
        skip: query.skip,
        take: query.limit,
      }),
      this.prisma.goldLedgerEntry.count({ where: { characterId } }),
    ]);
    return paginate(items, total, query);
  }
}
