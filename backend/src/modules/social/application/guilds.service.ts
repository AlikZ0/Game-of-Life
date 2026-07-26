import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Guild, GuildRole, LedgerReason, PvpMetric } from '@prisma/client';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { CharacterService } from '../../character/application/character.service';
import { RealtimeGateway } from '../../realtime/realtime.gateway';
import {
  CreateGuildDto,
  CreateGuildMissionDto,
  GuildMessageDto,
} from './dto/guild.dto';

const WEEK_MS = 7 * 86400000;
const LEADERBOARD_SIZE = 10;

/**
 * Guilds are cooperative clans: characters join a single guild, chat, climb the
 * weekly XP leaderboard and take on shared missions. Membership is enforced
 * one-per-character by the unique `GuildMember.characterId` index.
 */
@Injectable()
export class GuildsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeGateway,
    private readonly characters: CharacterService,
  ) {}

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
    const message = await this.prisma.guildMessage.create({
      data: { guildId, characterId, body: dto.body },
    });
    // Fan the message out to everyone currently in the guild room.
    this.realtime.emitGuildMessage(guildId, {
      id: message.id,
      characterId,
      body: message.body,
      createdAt: message.createdAt.toISOString(),
    });
    return message;
  }

  /**
   * Credit a member's weekly XP (called from the completion flow) and push the
   * refreshed top-N leaderboard to the guild room in real time. Best-effort and
   * a no-op for characters that aren't in a guild.
   */
  async recordWeeklyXp(characterId: string, xp: number): Promise<void> {
    if (xp <= 0) return;
    const member = await this.prisma.guildMember.findUnique({
      where: { characterId },
      select: { guildId: true },
    });
    if (!member) return;

    await this.prisma.$transaction([
      this.prisma.guildMember.update({
        where: { characterId },
        data: { weeklyXp: { increment: xp } },
      }),
      this.prisma.guild.update({
        where: { id: member.guildId },
        data: { xp: { increment: BigInt(xp) } },
      }),
    ]);

    const top = await this.prisma.guildMember.findMany({
      where: { guildId: member.guildId },
      orderBy: { weeklyXp: 'desc' },
      take: LEADERBOARD_SIZE,
      include: { character: { select: { id: true, name: true, level: true } } },
    });
    this.realtime.emitLeaderboardUpdate(member.guildId, {
      guildId: member.guildId,
      standings: top.map((m, i) => ({
        rank: i + 1,
        characterId: m.characterId,
        name: m.character.name,
        level: m.character.level,
        weeklyXp: m.weeklyXp,
      })),
    });

    // XP contributions also push the guild's shared XP missions forward.
    await this.advanceMissions(member.guildId, PvpMetric.XP, xp);
  }

  /**
   * Advance a guild's active missions of the given metric by `amount`. Any
   * mission that reaches its target is marked complete and its gold reward is
   * granted to every current member (best-effort). Idempotent per mission via
   * the `completedAt` guard.
   */
  async advanceMissions(
    guildId: string,
    metric: PvpMetric,
    amount: number,
  ): Promise<void> {
    if (amount <= 0) return;
    const now = new Date();
    const missions = await this.prisma.guildMission.findMany({
      where: {
        guildId,
        metric,
        completedAt: null,
        expiresAt: { gt: now },
      },
    });

    for (const mission of missions) {
      const newValue = mission.currentValue + amount;
      const reached = newValue >= mission.targetValue;
      // Guard completion with `completedAt: null` so concurrent updates only
      // fire the reward once.
      const updated = await this.prisma.guildMission.updateMany({
        where: { id: mission.id, completedAt: null },
        data: {
          currentValue: newValue,
          completedAt: reached ? now : null,
        },
      });
      if (reached && updated.count > 0 && mission.rewardGold > 0) {
        await this.grantMissionReward(guildId, mission.id, mission.rewardGold);
      }
    }
  }

  /** Split the mission's gold reward to every current guild member. */
  private async grantMissionReward(
    guildId: string,
    missionId: string,
    rewardGold: number,
  ): Promise<void> {
    const members = await this.prisma.guildMember.findMany({
      where: { guildId },
      select: { characterId: true },
    });
    await Promise.all(
      members.map((m) =>
        this.characters
          .awardRewards({
            characterId: m.characterId,
            xp: 0,
            gold: rewardGold,
            reason: LedgerReason.GUILD_MISSION,
            refId: missionId,
          })
          .catch(() => undefined),
      ),
    );
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
