import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsString, Length } from 'class-validator';
import { PvpMetric } from '@prisma/client';

export class CreatePvpChallengeDto {
  @ApiProperty({
    description: 'characterId of the opponent to challenge',
    example: 'ckxyz...',
  })
  @IsString()
  @Length(1, 64)
  opponentId!: string;

  @ApiProperty({ enum: PvpMetric, example: PvpMetric.XP })
  @IsEnum(PvpMetric)
  metric!: PvpMetric;
}
