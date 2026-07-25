import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsISO8601,
  IsOptional,
  IsString,
  Length,
  Min,
} from 'class-validator';
import { PvpMetric } from '@prisma/client';

export class CreateGuildDto {
  @ApiProperty({ example: 'Dawn Raiders' })
  @IsString()
  @Length(3, 40)
  name!: string;

  @ApiProperty({ example: 'DAWN', description: 'Short 2–5 char tag' })
  @IsString()
  @Length(2, 5)
  tag!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 300)
  description?: string;
}

export class GuildMessageDto {
  @ApiProperty({ example: 'Great work on the weekly mission, everyone!' })
  @IsString()
  @Length(1, 500)
  body!: string;
}

export class CreateGuildMissionDto {
  @ApiProperty({ example: 'Collectively earn 50,000 XP this week' })
  @IsString()
  @Length(3, 120)
  title!: string;

  @ApiProperty({ example: 50000 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  targetValue!: number;

  @ApiPropertyOptional({ enum: PvpMetric, default: PvpMetric.XP })
  @IsOptional()
  @IsEnum(PvpMetric)
  metric?: PvpMetric;

  @ApiPropertyOptional({ example: 1000 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  rewardGold?: number;

  @ApiPropertyOptional({
    description: 'ISO date the mission expires; defaults to +7 days',
  })
  @IsOptional()
  @IsISO8601()
  expiresAt?: string;
}
