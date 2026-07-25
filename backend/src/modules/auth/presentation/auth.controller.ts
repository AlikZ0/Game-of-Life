import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
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

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  private ctx(req: Request): RequestContext {
    return { userAgent: req.headers['user-agent'], ip: req.ip };
  }

  @Public()
  @Post('register')
  @ApiOperation({ summary: 'Create an account with email + password' })
  register(
    @Body() dto: RegisterDto,
    @Req() req: Request,
  ): Promise<AuthTokensDto> {
    return this.auth.register(dto.email, dto.password, this.ctx(req));
  }

  @Public()
  @Post('login')
  @ApiOperation({ summary: 'Log in with email + password' })
  login(@Body() dto: LoginDto, @Req() req: Request): Promise<AuthTokensDto> {
    return this.auth.login(dto.email, dto.password, this.ctx(req));
  }

  @Public()
  @Post('google')
  @ApiOperation({ summary: 'Log in / sign up with a Google ID token' })
  google(@Body() dto: OAuthDto, @Req() req: Request): Promise<AuthTokensDto> {
    return this.auth.loginWithGoogle(dto.idToken, this.ctx(req));
  }

  @Public()
  @Post('apple')
  @ApiOperation({ summary: 'Log in / sign up with an Apple identity token' })
  apple(@Body() dto: OAuthDto, @Req() req: Request): Promise<AuthTokensDto> {
    return this.auth.loginWithApple(dto.idToken, this.ctx(req));
  }

  @Public()
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
