import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Request } from 'express';
import {
  AuthenticatedUser,
  CurrentUser,
} from '../../../common/decorators/current-user.decorator';
import { Public } from '../../../common/decorators/public.decorator';
import { AuthService, RequestContext } from '../application/auth.service';
import {
  AuthTokensDto,
  LoginDto,
  OAuthDto,
  RefreshDto,
  RegisterDto,
} from '../application/dto/auth.dto';

// Unauthenticated auth endpoints are the prime target for brute-force and
// account-creation abuse, so they get far tighter per-IP limits than the
// global default (which stays in force for the rest of the API).
const MINUTE = 60_000;
const CREDENTIALS_THROTTLE = { default: { limit: 8, ttl: MINUTE } };
const REGISTER_THROTTLE = { default: { limit: 6, ttl: MINUTE } };
const OAUTH_THROTTLE = { default: { limit: 12, ttl: MINUTE } };
const REFRESH_THROTTLE = { default: { limit: 20, ttl: MINUTE } };

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  private ctx(req: Request): RequestContext {
    return { userAgent: req.headers['user-agent'], ip: req.ip };
  }

  @Public()
  @Throttle(REGISTER_THROTTLE)
  @Post('register')
  @ApiOperation({ summary: 'Create an account with email + password' })
  register(
    @Body() dto: RegisterDto,
    @Req() req: Request,
  ): Promise<AuthTokensDto> {
    return this.auth.register(dto.email, dto.password, this.ctx(req));
  }

  @Public()
  @Throttle(CREDENTIALS_THROTTLE)
  @Post('login')
  @ApiOperation({ summary: 'Log in with email + password' })
  login(@Body() dto: LoginDto, @Req() req: Request): Promise<AuthTokensDto> {
    return this.auth.login(dto.email, dto.password, this.ctx(req));
  }

  @Public()
  @Throttle(OAUTH_THROTTLE)
  @Post('google')
  @ApiOperation({ summary: 'Log in / sign up with a Google ID token' })
  google(@Body() dto: OAuthDto, @Req() req: Request): Promise<AuthTokensDto> {
    return this.auth.loginWithGoogle(dto.idToken, this.ctx(req));
  }

  @Public()
  @Throttle(OAUTH_THROTTLE)
  @Post('apple')
  @ApiOperation({ summary: 'Log in / sign up with an Apple identity token' })
  apple(@Body() dto: OAuthDto, @Req() req: Request): Promise<AuthTokensDto> {
    return this.auth.loginWithApple(dto.idToken, this.ctx(req));
  }

  @Public()
  @Throttle(REFRESH_THROTTLE)
  @Post('refresh')
  @ApiOperation({ summary: 'Exchange a refresh token for a new token pair' })
  refresh(
    @Body() dto: RefreshDto,
    @Req() req: Request,
  ): Promise<AuthTokensDto> {
    return this.auth.refresh(dto.refreshToken, this.ctx(req));
  }

  @Post('logout')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke the supplied refresh token' })
  async logout(@Body() dto: RefreshDto): Promise<{ success: boolean }> {
    await this.auth.logout(dto.refreshToken);
    return { success: true };
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Return the authenticated principal' })
  me(@CurrentUser() user: AuthenticatedUser): AuthenticatedUser {
    return user;
  }
}
