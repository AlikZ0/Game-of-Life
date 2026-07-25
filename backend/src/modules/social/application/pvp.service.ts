import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PvpChallenge, PvpMetric, PvpStatus } from '@prisma/client';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { CreatePvpChallengeDto } from './dto/pvp.dto';

const CHALLENGE_WINDOW_MS = 7 * 86400000;

/**
 * 1-v-1 duels: a challenger picks an opponent and a metric (XP, quests, study
 * minutes, …); whoever accumulates more of that metric over a 7-day window wins.
 * Progress is fed in from the completion flows via {@link recordProgress}.
 */
@Injectable()
export class PvpService {
  constructor(private readonly prisma: PrismaService) {}

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
   * Finalize an ACTIVE challenge whose window has closed: mark it FINISHED and
   * stamp the winner (null on a draw). Invoked by the scheduled worker.
   */
  async finalize(id: string): Promise<PvpChallenge> {
    const challenge = await this.prisma.pvpChallenge.findUnique({
      where: { id },
    });
    if (!challenge) throw new NotFoundException('Challenge not found');
    const winnerId = this.decideWinner(challenge);
    return this.prisma.pvpChallenge.update({
      where: { id },
      data: { status: PvpStatus.FINISHED, winnerId },
    });
  }

  private decideWinner(c: PvpChallenge): string | null {
    if (c.challengerScore === c.opponentScore) return null;
    return c.challengerScore > c.opponentScore ? c.challengerId : c.opponentId;
  }
}
