import { ApiProperty } from '@nestjs/swagger';
import {
  IsEmail,
  IsNotEmpty,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'hero@lifequest.app' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'Str0ng-Passw0rd!', minLength: 8 })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password!: string;
}

export class LoginDto {
  @ApiProperty({ example: 'hero@lifequest.app' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'Str0ng-Passw0rd!' })
  @IsString()
  @IsNotEmpty()
  password!: string;
}

export class OAuthDto {
  @ApiProperty({ description: 'ID token returned by Google/Apple SDK' })
  @IsString()
  @IsNotEmpty()
  idToken!: string;
}

export class RefreshDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}

export class AuthTokensDto {
  @ApiProperty()
  accessToken!: string;

  @ApiProperty()
  refreshToken!: string;

  @ApiProperty({ example: 900, description: 'Access token TTL in seconds' })
  expiresIn!: number;

  @ApiProperty()
  hasCharacter!: boolean;
}
