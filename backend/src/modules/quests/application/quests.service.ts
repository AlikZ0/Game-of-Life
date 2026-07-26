import { InjectQueue } from '@nestjs/bullmq';
import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  LedgerReason,
  Prisma,
  PvpMetric,
  Quest,
  QuestCadence,
} from '@prisma/client';
import { Queue } from 'bullmq';
import { periodKeyFor } from '../../../common/utils/period';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { BossesService } from '../../bosses/application/bosses.service';
import { CharacterService } from '../../character/application/character.service';
import {
  GAMIFICATION_QUEUE,
  GamificationJob,
} from '../../gamification/gamification.constants';
import {
  computeReward,
  streakMultiplier,
} from '../../gamification/domain/rewards';
import { BattlePassService } from '../../monetization/application/battle-pass.service';
import { RealtimeGateway } from '../../realtime/realtime.gateway';
import { GuildsService } from '../../social/application/guilds.service';
import { PvpService } from '../../social/application/pvp.service';
import { StreaksService } from '../../streaks/application/streaks.service';
import { QUEST_REPOSITORY, QuestRepository } from '../domain/quest.repository';
import {
  CreateQuestDto,
  QuestCompletionResultDto,
  QuestResponseDto,
  UpdateQuestDto,
} from './dto/quest.dto';

@Injectable()
export class QuestsService {
  constructor(
    @Inject(QUEST_REPOSITORY) private readonly quests: QuestRepository,
    private readonly prisma: PrismaService,
    private readonly characters: CharacterService,
    private readonly bosses: BossesService,
    private readonly streaks: StreaksService,
    private readonly realtime: RealtimeGateway,
    private readonly guilds: GuildsService,
    private readonly pvp: PvpService,
    private readonly battlePass: BattlePassService,
    @InjectQueue(GAMIFICATION_QUEUE)
    private readonly gamificationQueue: Queue<GamificationJob>,
  ) {}

  private async characterId(userId: string): Promise<string> {
    const c = await this.prisma.character.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!c) throw new NotFoundException('Character not found');
    return c.id;
  }

  async create(userId: string, dto: CreateQuestDto): Promise<QuestResponseDto> {
    const characterId = await this.characterId(userId);
    const quest = await this.quests.create({
      characterId,
      title: dto.title,
      description: dto.description,
      cadence: dto.cadence,
      difficulty: dto.difficulty,
      skillKey: dto.skillKey,
      xpReward: dto.xpReward ?? 20,
      goldReward: dto.goldReward ?? 10,
      energyCost: dto.energyCost ?? 10,
      bossId: dto.bossId,
      repeatRule: (dto.repeatRule as Prisma.InputJsonValue) ?? undefined,
    });
    return this.toDto(quest, false);
  }

  async list(
    userId: string,
    cadence?: QuestCadence,
  ): Promise<QuestResponseDto[]> {
    const characterId = await this.characterId(userId);
    const quests = await this.quests.findMany({ characterId, cadence });
    // Batch-resolve which quests are already completed this period.
    const results = await Promise.all(
      quests.map(async (q) => {
        const done = await this.isCompletedThisPeriod(q);
        return this.toDto(q, done);
      }),
    );
    return results;
  }

  async update(
    userId: string,
    id: string,
    dto: UpdateQuestDto,
  ): Promise<QuestResponseDto> {
    await this.assertOwnership(userId, id);
    const quest = await this.quests.update(id, {
      title: dto.title,
      description: dto.description,
      cadence: dto.cadence,
      difficulty: dto.difficulty,
      skillKey: dto.skillKey,
      xpReward: dto.xpReward,
      goldReward: dto.goldReward,
      energyCost: dto.energyCost,
      repeatRule: (dto.repeatRule as Prisma.InputJsonValue) ?? undefined,
    });
    return this.toDto(quest, await this.isCompletedThisPeriod(quest));
  }

  async remove(userId: string, id: string): Promise<void> {
    await this.assertOwnership(userId, id);
    await this.quests.softDelete(id);
  }

  /**
   * Complete a quest for the current period. This is the game's core loop:
   *   idempotency guard → compute rewards (difficulty × streak) → award to
   *   character/skill/gold → damage a linked boss → advance the streak.
   */
  async complete(
    userId: string,
    id: string,
  ): Promise<QuestCompletionResultDto> {
    const characterId = await this.characterId(userId);
    const quest = await this.quests.findById(id);
    if (!quest || quest.characterId !== characterId) {
      throw new NotFoundException('Quest not found');
    }
    if (quest.status !== 'ACTIVE') {
      throw new ConflictException('Quest is not active');
    }

    const periodKey = periodKeyFor(quest.cadence);

    // Advance streak first so the multiplier reflects today's activity.
    const streakState = await this.streaks.registerActivity(characterId);
    const multiplier = streakMultiplier(streakState.current);

    const reward = computeReward({
      baseXp: quest.xpReward,
      baseGold: quest.goldReward,
      baseEnergyCost: quest.energyCost,
      baseDamage: quest.damage,
      difficulty: quest.difficulty,
      streakMultiplier: multiplier,
    });

    // Idempotency: the unique (questId, periodKey) index rejects a double
    // completion within the same period.
    try {
      await this.prisma.questCompletion.create({
        data: {
          questId: quest.id,
          characterId,
          periodKey,
          xpAwarded: reward.xp,
          goldAwarded: reward.gold,
        },
      });
    } catch (e) {
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002'
      ) {
        throw new ConflictException('Quest already completed this period');
      }
      throw e;
    }

    // One-off quests are archived after their single completion.
    if (quest.cadence === QuestCadence.ONE_OFF) {
      await this.quests.update(quest.id, { status: 'COMPLETED' });
    }

    const award = await this.characters.awardRewards({
      characterId,
      xp: reward.xp,
      gold: reward.gold + (streakState.bonusGold ?? 0),
      energyCost: reward.energyCost,
      skillKey: quest.skillKey,
      reason: LedgerReason.QUEST_REWARD,
      refId: quest.id,
    });

    let bossDamage: number | undefined;
    let bossDefeated: boolean | undefined;
    if (quest.bossId) {
      const dmg = await this.bosses.applyDamage(
        characterId,
        quest.bossId,
        reward.damage,
      );
      bossDamage = reward.damage;
      bossDefeated = dmg.defeated;
    }

    // Push live celebration events to the player's device(s)…
    if (award.levelsGained > 0) {
      this.realtime.emitLevelUp(characterId, {
        newLevel: award.character.level,
        levelsGained: award.levelsGained,
      });
    }
    if (bossDefeated && quest.bossId) {
      this.realtime.emitBossDefeated(characterId, { bossId: quest.bossId });
    }
    // …and evaluate achievements off the request path (best-effort).
    await this.enqueueAchievementEvaluation(characterId);
    // Credit the player's guild weekly leaderboard (no-op if not in a guild).
    await this.guilds
      .recordWeeklyXp(characterId, reward.xp)
      .catch(() => undefined);
    // Advance the seasonal Battle Pass (no-op when no season is active).
    await this.battlePass.addXp(characterId, reward.xp).catch(() => undefined);
    // Score any active PvP duels + guild missions this counts toward. XP is
    // already credited to the guild by recordWeeklyXp above; here we feed the
    // quests-completed signal to both subsystems.
    await Promise.all([
      this.pvp
        .recordProgress(characterId, PvpMetric.XP, reward.xp)
        .catch(() => undefined),
      this.pvp
        .recordProgress(characterId, PvpMetric.QUESTS_COMPLETED, 1)
        .catch(() => undefined),
      this.guilds
        .recordActivity(characterId, PvpMetric.QUESTS_COMPLETED, 1)
        .catch(() => undefined),
    ]);

    return {
      questId: quest.id,
      xpAwarded: reward.xp,
      goldAwarded: reward.gold + (streakState.bonusGold ?? 0),
      levelsGained: award.levelsGained,
      newLevel: award.character.level,
      goldBalance: award.goldBalance,
      bossDamage,
      bossDefeated,
      streak: streakState.current,
    };
  }

  /**
   * Enqueue asynchronous achievement evaluation for the character. Failures to
   * enqueue (e.g. a transient Redis outage) must never fail the completion the
   * player already earned, so they are swallowed and logged by the queue layer.
   */
  private async enqueueAchievementEvaluation(
    characterId: string,
  ): Promise<void> {
    try {
      await this.gamificationQueue.add(
        'evaluate-achievements',
        { type: 'evaluate-achievements', characterId },
        { removeOnComplete: true, removeOnFail: 100, attempts: 3 },
      );
    } catch {
      // best-effort: achievements are recomputed on next completion / on demand
    }
  }

  private async assertOwnership(
    userId: string,
    questId: string,
  ): Promise<void> {
    const characterId = await this.characterId(userId);
    const quest = await this.quests.findById(questId);
    if (!quest) throw new NotFoundException('Quest not found');
    if (quest.characterId !== characterId) throw new ForbiddenException();
  }

  private async isCompletedThisPeriod(quest: Quest): Promise<boolean> {
    const completion = await this.prisma.questCompletion.findUnique({
      where: {
        questId_periodKey: {
          questId: quest.id,
          periodKey: periodKeyFor(quest.cadence),
        },
      },
    });
    return Boolean(completion);
  }

  private toDto(quest: Quest, completedThisPeriod: boolean): QuestResponseDto {
    return {
      id: quest.id,
      title: quest.title,
      description: quest.description,
      cadence: quest.cadence,
      difficulty: quest.difficulty,
      status: quest.status,
      xpReward: quest.xpReward,
      goldReward: quest.goldReward,
      skillKey: quest.skillKey,
      energyCost: quest.energyCost,
      bossId: quest.bossId,
      completedThisPeriod,
    };
  }
}
