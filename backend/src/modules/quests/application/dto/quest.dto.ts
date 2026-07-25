import {
  ApiProperty,
  ApiPropertyOptional,
  PartialType,
} from '@nestjs/swagger';
import { Difficulty, QuestCadence } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  Length,
  Min,
} from 'class-validator';

export class CreateQuestDto {
  @ApiProperty({ example: 'Code for 45 minutes' })
  @IsString()
  @Length(2, 120)
  title!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 500)
  description?: string;

  @ApiProperty({ enum: QuestCadence, default: QuestCadence.DAILY })
  @IsEnum(QuestCadence)
  cadence: QuestCadence = QuestCadence.DAILY;

  @ApiProperty({ enum: Difficulty, default: Difficulty.MEDIUM })
  @IsEnum(Difficulty)
  difficulty: Difficulty = Difficulty.MEDIUM;

  @ApiPropertyOptional({ example: 'programming', description: 'Skill to award XP to' })
  @IsOptional()
  @IsString()
  skillKey?: string;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  xpReward?: number;

  @ApiPropertyOptional({ default: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  goldReward?: number;

  @ApiPropertyOptional({ default: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  energyCost?: number;

  @ApiPropertyOptional({ description: 'Link this quest to a boss to deal damage' })
  @IsOptional()
  @IsString()
  bossId?: string;

  @ApiPropertyOptional({
    description: 'Recurrence rule, e.g. { "daysOfWeek": [1,3,5] }',
  })
  @IsOptional()
  @IsObject()
  repeatRule?: Record<string, unknown>;
}

export class UpdateQuestDto extends PartialType(CreateQuestDto) {}

export class QuestResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() title!: string;
  @ApiPropertyOptional() description?: string | null;
  @ApiProperty({ enum: QuestCadence }) cadence!: QuestCadence;
  @ApiProperty({ enum: Difficulty }) difficulty!: Difficulty;
  @ApiProperty() status!: string;
  @ApiProperty() xpReward!: number;
  @ApiProperty() goldReward!: number;
  @ApiPropertyOptional() skillKey?: string | null;
  @ApiProperty() energyCost!: number;
  @ApiPropertyOptional() bossId?: string | null;
  @ApiProperty({ description: 'Whether it is already completed this period' })
  completedThisPeriod!: boolean;
}

export class QuestCompletionResultDto {
  @ApiProperty() questId!: string;
  @ApiProperty() xpAwarded!: number;
  @ApiProperty() goldAwarded!: number;
  @ApiProperty() levelsGained!: number;
  @ApiProperty() newLevel!: number;
  @ApiProperty() goldBalance!: number;
  @ApiPropertyOptional({ description: 'Damage dealt to a linked boss, if any' })
  bossDamage?: number;
  @ApiPropertyOptional() bossDefeated?: boolean;
  @ApiProperty() streak!: number;
}
