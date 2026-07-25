import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthService } from './application/auth.service';
import { REFRESH_TOKEN_REPOSITORY } from './domain/refresh-token.repository';
import { USER_REPOSITORY } from './domain/user.repository';
import { JwtStrategy } from './infrastructure/jwt.strategy';
import { OAuthVerifier } from './infrastructure/oauth-verifier';
import { PasswordHasher } from './infrastructure/password.hasher';
import { PrismaRefreshTokenRepository } from './infrastructure/prisma-refresh-token.repository';
import { PrismaUserRepository } from './infrastructure/prisma-user.repository';
import { TokenService } from './infrastructure/token.service';
import { AuthController } from './presentation/auth.controller';

@Module({
  imports: [PassportModule, JwtModule.register({})],
  controllers: [AuthController],
  providers: [
    AuthService,
    TokenService,
    PasswordHasher,
    OAuthVerifier,
    JwtStrategy,
    { provide: USER_REPOSITORY, useClass: PrismaUserRepository },
    {
      provide: REFRESH_TOKEN_REPOSITORY,
      useClass: PrismaRefreshTokenRepository,
    },
  ],
  exports: [TokenService],
})
export class AuthModule {}
