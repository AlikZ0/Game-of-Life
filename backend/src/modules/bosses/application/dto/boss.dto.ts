import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Length, Min } from 'class-validator';

export class CreateBossDto {
  @ApiProperty({ example: 'Ship the App to the App Store' })
  @IsString()
  @Length(2, 120)
  name!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 500)
  description?: string;

  @ApiProperty({
    example: 500,
    description: 'Total HP — sum of expected quest damage',
  })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  maxHp!: number;

  @ApiPropertyOptional({ default: 500 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  rewardXp?: number;

  @ApiPropertyOptional({ default: 250 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  rewardGold?: number;

  @ApiPropertyOptional({ description: 'ISO deadline' })
  @IsOptional()
  @IsString()
  deadline?: string;
}

export class BossResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiPropertyOptional() description?: string | null;
  @ApiProperty() maxHp!: number;
  @ApiProperty() currentHp!: number;
  @ApiProperty({ description: '0..1 remaining HP fraction' })
  hpFraction!: number;
  @ApiProperty() status!: string;
  @ApiProperty() rewardXp!: number;
  @ApiProperty() rewardGold!: number;
  @ApiPropertyOptional() deadline?: Date | null;
  @ApiProperty({ description: 'Quests linked to this boss' })
  linkedQuests!: number;
}
