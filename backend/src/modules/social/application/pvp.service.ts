import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import {
  LedgerReason,
  PvpChallenge,
  PvpMetric,
  PvpStatus,
} from '@prisma/client';
import { LockService } from '../../../infra/redis/lock.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { CharacterService } from '../../character/application/character.service';
import { CreatePvpChallengeDto } from './dto/pvp.dto';

const CHALLENGE_WINDOW_MS = 7 * 86400000;
/** Flat reward granted to the winner when a duel is finalized. */
const PVP_WIN_XP = 200;
const PVP_WIN_GOLD = 100;

/**
 * 1-v-1 duels: a challenger picks an opponent and a metric (XP, quests, study
 * minutes, …); whoever accumulates more of that metric over a 7-day window wins.
 * Progress is fed in from the completion flows via {@link recordProgress}; a
 * scheduled job finalizes duels whose window has closed.
 */
@Injectable()
export class PvpService {
  private readonly logger = new Logger(PvpService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly characters: CharacterService,
    private readonly locks: LockService,
  ) {}

  /** Create a PENDING challenge with a 7-day window derived from "now". */
  async create(challengerId: string, dto: CreatePvpChallengeDto) {
    if (dto.opponentId === challengerId) {
      throw new BadRequestException('Cannot challenge yourself');
    }
    const opponent = await this.prisma.character.findUnique({
      where: { id: dto.opponentId },
      select: { id: true },
    });
    if (!opponent) throw new NotFoundException('Opponent not found');

    const startAt = new Date();
    const endAt = new Date(startAt.getTime() + CHALLENGE_WINDOW_MS);

    return this.prisma.pvpChallenge.create({
      data: {
        challengerId,
        opponentId: dto.opponentId,
        metric: dto.metric,
        status: PvpStatus.PENDING,
        startAt,
        endAt,
      },
    });
  }

  /** The opponent accepts, moving the challenge PENDING → ACTIVE. */
  async accept(characterId: string, id: string) {
    const challenge = await this.prisma.pvpChallenge.findUnique({
      where: { id },
    });
    if (!challenge) throw new NotFoundException('Challenge not found');
    if (challenge.opponentId !== characterId) {
      throw new ForbiddenException(
        'Only the opponent can accept this challenge',
      );
    }
    if (challenge.status !== PvpStatus.PENDING) {
      throw new BadRequestException('Challenge is no longer pending');
    }
    return this.prisma.pvpChallenge.update({
      where: { id },
      data: { status: PvpStatus.ACTIVE },
    });
  }

  /** List challenges the character is involved in, as challenger or opponent. */
  listMine(characterId: string) {
    return this.prisma.pvpChallenge.findMany({
      where: {
        OR: [{ challengerId: characterId }, { opponentId: characterId }],
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async standings(id: string) {
    const challenge = await this.prisma.pvpChallenge.findUnique({
      where: { id },
    });
    if (!challenge) throw new NotFoundException('Challenge not found');
    return {
      id: challenge.id,
      metric: challenge.metric,
      status: challenge.status,
      startAt: challenge.startAt,
      endAt: challenge.endAt,
      challengerId: challenge.challengerId,
      opponentId: challenge.opponentId,
      challengerScore: challenge.challengerScore,
      opponentScore: challenge.opponentScore,
      winnerId:
        challenge.status === PvpStatus.FINISHED ? challenge.winnerId : null,
    };
  }

  /**
   * Record metric progress toward any ACTIVE challenges the character is part of.
   * Called from the quest/skill/boss completion flows (and the daily cron that
   * finalizes expired challenges) — kept as a simple, side-effect-light increment
   * so callers never need to know challenge internals.
   *
   * @param characterId the character that just made progress
   * @param metric      which metric the progress counts toward
   * @param amount      how much to add to that character's score
   */
  async recordProgress(
    characterId: string,
    metric: PvpMetric,
    amount: number,
  ): Promise<void> {
    if (amount <= 0) return;
    const now = new Date();
    const active = await this.prisma.pvpChallenge.findMany({
      where: {
        metric,
        status: PvpStatus.ACTIVE,
        startAt: { lte: now },
        endAt: { gte: now },
        OR: [{ challengerId: characterId }, { opponentId: characterId }],
      },
    });

    for (const challenge of active) {
      const isChallenger = challenge.challengerId === characterId;
      await this.prisma.pvpChallenge.update({
        where: { id: challenge.id },
        data: isChallenger
          ? { challengerScore: { increment: amount } }
          : { opponentScore: { increment: amount } },
      });
    }
  }

  /**
   * Finalize an ACTIVE challenge whose window has closed: mark it FINISHED,
   * stamp the winner (null on a draw), and grant the winner their reward.
   */
  async finalize(id: string): Promise<PvpChallenge> {
    const challenge = await this.prisma.pvpChallenge.findUnique({
      where: { id },
    });
    if (!challenge) throw new NotFoundException('Challenge not found');
    if (challenge.status === PvpStatus.FINISHED) return challenge;

    const winnerId = this.decideWinner(challenge);
    const updated = await this.prisma.pvpChallenge.update({
      where: { id },
      data: { status: PvpStatus.FINISHED, winnerId },
    });

    if (winnerId) {
      await this.characters
        .awardRewards({
          characterId: winnerId,
          xp: PVP_WIN_XP,
          gold: PVP_WIN_GOLD,
          reason: LedgerReason.PVP_REWARD,
          refId: challenge.id,
        })
        .catch((err) =>
          this.logger.warn(`PvP reward failed for ${winnerId}: ${String(err)}`),
        );
    }
    return updated;
  }

  /**
   * Hourly sweep that finalizes every ACTIVE challenge whose window has closed.
   * NOTE: on a multi-replica deployment this should run under a distributed lock
   * (or on a single scheduler/worker) to avoid double-finalizing — tracked as a
   * scaling follow-up.
   */
  @Cron(CronExpression.EVERY_HOUR)
  async finalizeDueChallenges(): Promise<void> {
    // Single-flight across replicas: only the holder of the lock runs the sweep.
    await this.locks.withLock('pvp:finalize', 55 * 60 * 1000, async () => {
      const now = new Date();
      const due = await this.prisma.pvpChallenge.findMany({
        where: { status: PvpStatus.ACTIVE, endAt: { lt: now } },
        select: { id: true },
      });
      for (const { id } of due) {
        await this.finalize(id).catch((err) =>
          this.logger.warn(`Failed to finalize ${id}: ${String(err)}`),
        );
      }
      if (due.length) {
        this.logger.log(`Finalized ${due.length} due PvP challenge(s)`);
      }
    });
  }

  private decideWinner(c: PvpChallenge): string | null {
    if (c.challengerScore === c.opponentScore) return null;
    return c.challengerScore > c.opponentScore ? c.challengerId : c.opponentId;
  }
}
