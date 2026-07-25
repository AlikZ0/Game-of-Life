import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Guild, GuildRole, PvpMetric } from '@prisma/client';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import {
  CreateGuildDto,
  CreateGuildMissionDto,
  GuildMessageDto,
} from './dto/guild.dto';

const WEEK_MS = 7 * 86400000;

/**
 * Guilds are cooperative clans: characters join a single guild, chat, climb the
 * weekly XP leaderboard and take on shared missions. Membership is enforced
 * one-per-character by the unique `GuildMember.characterId` index.
 */
@Injectable()
export class GuildsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Create a guild; the creator is enrolled as its LEADER. */
  async create(characterId: string, dto: CreateGuildDto) {
    const existing = await this.prisma.guildMember.findUnique({
      where: { characterId },
    });
    if (existing) {
      throw new BadRequestException('Already a member of a guild');
    }

    const guild = await this.prisma.$transaction(async (tx) => {
      const created = await tx.guild.create({
        data: {
          name: dto.name,
          tag: dto.tag.toUpperCase(),
          description: dto.description,
        },
      });
      await tx.guildMember.create({
        data: {
          guildId: created.id,
          characterId,
          role: GuildRole.LEADER,
        },
      });
      return created;
    });

    return this.serialize(guild);
  }

  async get(id: string) {
    const guild = await this.prisma.guild.findUnique({
      where: { id },
      include: {
        members: {
          include: {
            character: { select: { id: true, name: true, level: true } },
          },
          orderBy: { weeklyXp: 'desc' },
        },
        _count: { select: { members: true } },
      },
    });
    if (!guild) throw new NotFoundException('Guild not found');
    return { ...this.serialize(guild), members: guild.members };
  }

  /** Join a guild, rejecting characters that already belong to one. */
  async join(characterId: string, guildId: string) {
    const guild = await this.prisma.guild.findUnique({
      where: { id: guildId },
    });
    if (!guild) throw new NotFoundException('Guild not found');

    const existing = await this.prisma.guildMember.findUnique({
      where: { characterId },
    });
    if (existing) {
      throw new BadRequestException('Already a member of a guild');
    }

    return this.prisma.guildMember.create({
      data: { guildId, characterId, role: GuildRole.MEMBER },
    });
  }

  async leave(characterId: string, guildId: string) {
    const member = await this.prisma.guildMember.findUnique({
      where: { characterId },
    });
    if (!member || member.guildId !== guildId) {
      throw new NotFoundException('Not a member of this guild');
    }
    await this.prisma.guildMember.delete({ where: { characterId } });
    return { success: true };
  }

  /** Members ranked by weekly XP (resets are handled by the weekly cron). */
  async leaderboard(guildId: string) {
    return this.prisma.guildMember.findMany({
      where: { guildId },
      orderBy: { weeklyXp: 'desc' },
      include: {
        character: {
          select: { id: true, name: true, level: true, avatarKey: true },
        },
      },
    });
  }

  async messages(guildId: string, take = 50) {
    const messages = await this.prisma.guildMessage.findMany({
      where: { guildId },
      orderBy: { createdAt: 'desc' },
      take,
    });
    return messages.reverse(); // chronological for the client
  }

  async postMessage(
    characterId: string,
    guildId: string,
    dto: GuildMessageDto,
  ) {
    await this.assertMember(characterId, guildId);
    return this.prisma.guildMessage.create({
      data: { guildId, characterId, body: dto.body },
    });
  }

  listMissions(guildId: string) {
    return this.prisma.guildMission.findMany({
      where: { guildId },
      orderBy: { createdAt: 'desc' },
    });
  }

  /** Only the guild LEADER may create missions. */
  async createMission(
    characterId: string,
    guildId: string,
    dto: CreateGuildMissionDto,
  ) {
    const member = await this.assertMember(characterId, guildId);
    if (member.role !== GuildRole.LEADER) {
      throw new ForbiddenException('Only the guild leader can create missions');
    }
    return this.prisma.guildMission.create({
      data: {
        guildId,
        title: dto.title,
        targetValue: dto.targetValue,
        metric: dto.metric ?? PvpMetric.XP,
        rewardGold: dto.rewardGold ?? 0,
        expiresAt: dto.expiresAt
          ? new Date(dto.expiresAt)
          : new Date(Date.now() + WEEK_MS),
      },
    });
  }

  private async assertMember(characterId: string, guildId: string) {
    const member = await this.prisma.guildMember.findUnique({
      where: { characterId },
    });
    if (!member || member.guildId !== guildId) {
      throw new ForbiddenException('Not a member of this guild');
    }
    return member;
  }

  /** BigInt `xp` cannot be JSON-serialized directly, so we stringify it. */
  private serialize(guild: Guild) {
    return { ...guild, xp: guild.xp.toString() };
  }
}
