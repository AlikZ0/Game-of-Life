import {
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Character, LedgerReason, Prisma } from '@prisma/client';
import {
  applyXp,
  levelProgress,
  xpForLevel,
} from '../../gamification/domain/leveling';
import { DEFAULT_SKILLS } from '../../skills/domain/skill-catalog';
import {
  CHARACTER_REPOSITORY,
  CharacterRepository,
} from '../domain/character.repository';
import {
  CharacterResponseDto,
  CreateCharacterDto,
  UpdateCharacterDto,
} from './dto/character.dto';

export interface AwardInput {
  characterId: string;
  xp: number;
  gold: number;
  energyCost?: number;
  skillKey?: string | null;
  reason: LedgerReason;
  refId?: string;
}

export interface AwardResult {
  character: CharacterResponseDto;
  levelsGained: number;
  goldBalance: number;
}

/** HP/Energy grow with level so higher-level characters can take on more. */
const HP_PER_LEVEL = 10;
const ENERGY_PER_LEVEL = 5;

@Injectable()
export class CharacterService {
  constructor(
    @Inject(CHARACTER_REPOSITORY)
    private readonly characters: CharacterRepository,
  ) {}

  async create(
    userId: string,
    dto: CreateCharacterDto,
  ): Promise<CharacterResponseDto> {
    const existing = await this.characters.findByUserId(userId);
    if (existing) throw new ConflictException('Character already exists');

    const character = await this.characters.transaction(async (tx) => {
      const created = await tx.character.create({
        data: {
          userId,
          name: dto.name,
          avatarKey: dto.avatarKey ?? 'default',
          characterClass: dto.characterClass,
        },
      });
      // Seed the standard skill tree + a fresh streak record.
      await tx.skill.createMany({
        data: DEFAULT_SKILLS.map((s) => ({
          characterId: created.id,
          key: s.key,
          name: s.name,
          icon: s.icon,
          color: s.color,
        })),
      });
      await tx.streak.create({ data: { characterId: created.id } });
      return created;
    });

    return this.toDto(character);
  }

  async getByUserId(userId: string): Promise<CharacterResponseDto> {
    const character = await this.characters.findByUserId(userId);
    if (!character) throw new NotFoundException('Character not found');
    return this.toDto(character);
  }

  async update(
    userId: string,
    dto: UpdateCharacterDto,
  ): Promise<CharacterResponseDto> {
    const character = await this.characters.findByUserId(userId);
    if (!character) throw new NotFoundException('Character not found');
    const updated = await this.characters.update(character.id, {
      name: dto.name ?? undefined,
      avatarKey: dto.avatarKey ?? undefined,
      activeTitle: dto.activeTitle ?? undefined,
    });
    return this.toDto(updated);
  }

  /**
   * Atomically apply a reward bundle to a character: character XP (+levels),
   * optional skill XP, gold (with an append-only ledger entry) and energy cost.
   * Called by the quest / boss / achievement / streak completion flows.
   */
  async awardRewards(input: AwardInput): Promise<AwardResult> {
    return this.characters.transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: input.characterId },
      });
      if (!character) throw new NotFoundException('Character not found');

      // 1) Character progression
      const prog = applyXp(
        { level: character.level, xp: character.xp },
        input.xp,
      );
      const maxHp = 100 + (prog.level - 1) * HP_PER_LEVEL;
      const maxEnergy = 100 + (prog.level - 1) * ENERGY_PER_LEVEL;
      const energy = Math.max(
        0,
        Math.min(character.energy - (input.energyCost ?? 0), maxEnergy),
      );
      const newGold = character.gold + input.gold;

      const updated = await tx.character.update({
        where: { id: character.id },
        data: {
          level: prog.level,
          xp: prog.xp,
          totalXp: { increment: BigInt(input.xp) },
          gold: newGold,
          energy,
          maxHp,
          // heal to full on level-up as a reward
          hp: prog.levelsGained > 0 ? maxHp : Math.min(character.hp, maxHp),
          maxEnergy,
        },
      });

      // 2) Gold ledger (append-only, running balance)
      if (input.gold !== 0) {
        await tx.goldLedgerEntry.create({
          data: {
            characterId: character.id,
            delta: input.gold,
            balance: newGold,
            reason: input.reason,
            refId: input.refId,
          },
        });
      }

      // 3) Skill XP + history
      if (input.skillKey && input.xp > 0) {
        const skill = await tx.skill.findUnique({
          where: {
            characterId_key: { characterId: character.id, key: input.skillKey },
          },
        });
        if (skill) {
          const skillProg = applyXp(
            { level: skill.level, xp: skill.xp },
            input.xp,
          );
          await tx.skill.update({
            where: { id: skill.id },
            data: {
              level: skillProg.level,
              xp: skillProg.xp,
              totalXp: { increment: BigInt(input.xp) },
            },
          });
          await tx.skillXpEvent.create({
            data: {
              skillId: skill.id,
              amount: input.xp,
              source: input.refId ?? 'manual',
            },
          });
        }
      }

      return {
        character: this.toDto(updated),
        levelsGained: prog.levelsGained,
        goldBalance: newGold,
      };
    });
  }

  private toDto(c: Character): CharacterResponseDto {
    return {
      id: c.id,
      name: c.name,
      avatarKey: c.avatarKey,
      characterClass: c.characterClass,
      level: c.level,
      xp: c.xp,
      xpToNext: xpForLevel(c.level),
      levelProgress: levelProgress({ level: c.level, xp: c.xp }),
      totalXp: c.totalXp.toString(),
      gold: c.gold,
      hp: c.hp,
      maxHp: c.maxHp,
      energy: c.energy,
      maxEnergy: c.maxEnergy,
      activeTitle: c.activeTitle,
    };
  }
}
