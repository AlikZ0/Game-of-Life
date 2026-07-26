import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Boss, Difficulty, LedgerReason } from '@prisma/client';
import { periodKeyFor } from '../../../common/utils/period';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { CharacterService } from '../../character/application/character.service';
import { BossResponseDto, CreateBossDto } from './dto/boss.dto';

export interface DamageResult {
  boss: BossResponseDto;
  defeated: boolean;
  rewardXp?: number;
  rewardGold?: number;
}

export interface LinkedQuestDto {
  id: string;
  title: string;
  difficulty: Difficulty;
  damage: number;
  completedThisPeriod: boolean;
}

@Injectable()
export class BossesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly characters: CharacterService,
  ) {}

  async create(
    characterId: string,
    dto: CreateBossDto,
  ): Promise<BossResponseDto> {
    const boss = await this.prisma.boss.create({
      data: {
        characterId,
        name: dto.name,
        description: dto.description,
        maxHp: dto.maxHp,
        currentHp: dto.maxHp,
        rewardXp: dto.rewardXp ?? 500,
        rewardGold: dto.rewardGold ?? 250,
        deadline: dto.deadline ? new Date(dto.deadline) : null,
      },
    });
    return this.toDto(boss, 0);
  }

  async list(characterId: string): Promise<BossResponseDto[]> {
    const bosses = await this.prisma.boss.findMany({
      where: { characterId },
      orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
      include: { _count: { select: { quests: true } } },
    });
    return bosses.map((b) => this.toDto(b, b._count.quests));
  }

  async get(characterId: string, id: string): Promise<BossResponseDto> {
    const boss = await this.prisma.boss.findUnique({
      where: { id },
      include: { _count: { select: { quests: true } } },
    });
    if (!boss) throw new NotFoundException('Boss not found');
    if (boss.characterId !== characterId) throw new ForbiddenException();
    return this.toDto(boss, boss._count.quests);
  }

  /**
   * The ACTIVE quests wired to a boss — the "attacking quests" the mobile boss
   * detail screen lists, each with the damage it deals and whether it's already
   * been completed this period.
   */
  async linkedQuests(
    characterId: string,
    bossId: string,
  ): Promise<LinkedQuestDto[]> {
    const boss = await this.prisma.boss.findUnique({
      where: { id: bossId },
      select: { characterId: true },
    });
    if (!boss) throw new NotFoundException('Boss not found');
    if (boss.characterId !== characterId) throw new ForbiddenException();

    const quests = await this.prisma.quest.findMany({
      where: { bossId, characterId, status: 'ACTIVE' },
      orderBy: { createdAt: 'desc' },
    });

    return Promise.all(
      quests.map(async (q) => ({
        id: q.id,
        title: q.title,
        difficulty: q.difficulty,
        damage: q.damage,
        completedThisPeriod: Boolean(
          await this.prisma.questCompletion.findUnique({
            where: {
              questId_periodKey: {
                questId: q.id,
                periodKey: periodKeyFor(q.cadence),
              },
            },
          }),
        ),
      })),
    );
  }

  /**
   * Apply damage to a boss (called when a linked quest is completed). Runs in a
   * transaction; on reaching 0 HP the boss is marked defeated and its rewards
   * are granted to the character.
   */
  async applyDamage(
    characterId: string,
    bossId: string,
    damage: number,
  ): Promise<DamageResult> {
    const boss = await this.prisma.boss.findUnique({ where: { id: bossId } });
    if (!boss || boss.characterId !== characterId) {
      throw new NotFoundException('Boss not found');
    }
    if (boss.status !== 'ACTIVE') {
      return { boss: this.toDto(boss, 0), defeated: false };
    }

    const newHp = Math.max(0, boss.currentHp - damage);
    const defeated = newHp === 0;

    const updated = await this.prisma.boss.update({
      where: { id: bossId },
      data: {
        currentHp: newHp,
        status: defeated ? 'DEFEATED' : 'ACTIVE',
        defeatedAt: defeated ? new Date() : null,
      },
    });

    if (defeated) {
      await this.characters.awardRewards({
        characterId,
        xp: boss.rewardXp,
        gold: boss.rewardGold,
        reason: LedgerReason.BOSS_REWARD,
        refId: boss.id,
      });
      return {
        boss: this.toDto(updated, 0),
        defeated: true,
        rewardXp: boss.rewardXp,
        rewardGold: boss.rewardGold,
      };
    }
    return { boss: this.toDto(updated, 0), defeated: false };
  }

  private toDto(
    b: Boss | (Boss & Record<string, unknown>),
    linkedQuests: number,
  ): BossResponseDto {
    return {
      id: b.id,
      name: b.name,
      description: b.description,
      maxHp: b.maxHp,
      currentHp: b.currentHp,
      hpFraction: b.maxHp === 0 ? 0 : b.currentHp / b.maxHp,
      status: b.status,
      rewardXp: b.rewardXp,
      rewardGold: b.rewardGold,
      deadline: b.deadline,
      linkedQuests,
    };
  }
}
