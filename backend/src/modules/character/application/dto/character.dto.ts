import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CharacterClass } from '@prisma/client';
import { IsEnum, IsOptional, IsString, Length, Matches } from 'class-validator';

export class CreateCharacterDto {
  @ApiProperty({ example: 'Aria the Bold', minLength: 2, maxLength: 24 })
  @IsString()
  @Length(2, 24)
  name!: string;

  @ApiPropertyOptional({ example: 'avatar_04', default: 'default' })
  @IsOptional()
  @IsString()
  @Matches(/^[a-z0-9_]+$/, { message: 'avatarKey must be a catalog key' })
  avatarKey?: string;

  @ApiProperty({ enum: CharacterClass, example: CharacterClass.MAGE })
  @IsEnum(CharacterClass)
  characterClass!: CharacterClass;
}

export class UpdateCharacterDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(2, 24)
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  avatarKey?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  activeTitle?: string;
}

export class CharacterResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() avatarKey!: string;
  @ApiProperty({ enum: CharacterClass }) characterClass!: CharacterClass;
  @ApiProperty() level!: number;
  @ApiProperty() xp!: number;
  @ApiProperty({ description: 'XP required to reach the next level' })
  xpToNext!: number;
  @ApiProperty({ description: '0..1 progress within the current level' })
  levelProgress!: number;
  @ApiProperty() totalXp!: string; // BigInt serialised as string
  @ApiProperty() gold!: number;
  @ApiProperty() hp!: number;
  @ApiProperty() maxHp!: number;
  @ApiProperty() energy!: number;
  @ApiProperty() maxEnergy!: number;
  @ApiPropertyOptional() activeTitle?: string | null;
}
