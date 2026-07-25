import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  Length,
  Min,
} from 'class-validator';

export class CreateShopRewardDto {
  @ApiProperty({ example: '1 hour of gaming' })
  @IsString()
  @Length(2, 80)
  title!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 300)
  description?: string;

  @ApiProperty({ example: 150 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  goldCost!: number;

  @ApiPropertyOptional({ description: 'null = unlimited' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  stock?: number;
}
