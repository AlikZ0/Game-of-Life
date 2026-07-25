import {
  ConflictException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthProvider, User } from '@prisma/client';
import {
  REFRESH_TOKEN_REPOSITORY,
  RefreshTokenRepository,
} from '../domain/refresh-token.repository';
import { USER_REPOSITORY, UserRepository } from '../domain/user.repository';
import { OAuthVerifier } from '../infrastructure/oauth-verifier';
import { PasswordHasher } from '../infrastructure/password.hasher';
import { TokenService } from '../infrastructure/token.service';
import { AuthTokensDto } from './dto/auth.dto';

export interface RequestContext {
  userAgent?: string;
  ip?: string;
}

/**
 * Application service coordinating the authentication use cases. Depends only on
 * domain ports + infrastructure services (via DI tokens), never on Prisma
 * directly — keeping the use-case layer persistence-agnostic.
 */
@Injectable()
export class AuthService {
  constructor(
    @Inject(USER_REPOSITORY) private readonly users: UserRepository,
    @Inject(REFRESH_TOKEN_REPOSITORY)
    private readonly refreshTokens: RefreshTokenRepository,
    private readonly hasher: PasswordHasher,
    private readonly tokens: TokenService,
    private readonly oauth: OAuthVerifier,
  ) {}

  async register(
    email: string,
    password: string,
    ctx: RequestContext,
  ): Promise<AuthTokensDto> {
    const existing = await this.users.findByEmail(email);
    if (existing) throw new ConflictException('Email already registered');
    const passwordHash = await this.hasher.hash(password);
    const user = await this.users.create({
      email,
      passwordHash,
      provider: AuthProvider.EMAIL,
    });
    return this.issueTokens(user, ctx, false);
  }

  async login(
    email: string,
    password: string,
    ctx: RequestContext,
  ): Promise<AuthTokensDto> {
    const user = await this.users.findByEmail(email);
    if (!user?.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }
    const ok = await this.hasher.verify(user.passwordHash, password);
    if (!ok) throw new UnauthorizedException('Invalid credentials');
    await this.users.markLoggedIn(user.id);
    return this.issueTokens(user, ctx);
  }

  async loginWithGoogle(
    idToken: string,
    ctx: RequestContext,
  ): Promise<AuthTokensDto> {
    const profile = await this.oauth.verifyGoogle(idToken);
    return this.upsertOAuthUser(AuthProvider.GOOGLE, profile, ctx);
  }

  async loginWithApple(
    idToken: string,
    ctx: RequestContext,
  ): Promise<AuthTokensDto> {
    const profile = await this.oauth.verifyApple(idToken);
    return this.upsertOAuthUser(AuthProvider.APPLE, profile, ctx);
  }

  async refresh(rawToken: string, ctx: RequestContext): Promise<AuthTokensDto> {
    const hash = this.tokens.hashRefresh(rawToken);
    const stored = await this.refreshTokens.findValidByHash(hash);
    if (!stored) throw new UnauthorizedException('Invalid refresh token');
    // Rotate: revoke the used token, issue a fresh pair.
    await this.refreshTokens.revoke(stored.id);
    const user = await this.users.findById(stored.userId);
    if (!user) throw new UnauthorizedException('User not found');
    return this.issueTokens(user, ctx);
  }

  async logout(rawToken: string): Promise<void> {
    const hash = this.tokens.hashRefresh(rawToken);
    const stored = await this.refreshTokens.findValidByHash(hash);
    if (stored) await this.refreshTokens.revoke(stored.id);
  }

  private async upsertOAuthUser(
    provider: AuthProvider,
    profile: { providerId: string; email: string; emailVerified: boolean },
    ctx: RequestContext,
  ): Promise<AuthTokensDto> {
    let user = await this.users.findByProvider(provider, profile.providerId);
    if (!user) {
      // Link to an existing email account if present, else create.
      user =
        (await this.users.findByEmail(profile.email)) ??
        (await this.users.create({
          email: profile.email,
          provider,
          providerId: profile.providerId,
          emailVerified: profile.emailVerified,
        }));
    }
    await this.users.markLoggedIn(user.id);
    return this.issueTokens(user, ctx);
  }

  private async issueTokens(
    user: User & { character?: { id: string } | null },
    ctx: RequestContext,
    hasCharacterHint?: boolean,
  ): Promise<AuthTokensDto> {
    const characterId = user.character?.id;
    const accessToken = await this.tokens.signAccessToken({
      sub: user.id,
      email: user.email,
      characterId,
    });
    const refresh = this.tokens.generateRefreshToken();
    await this.refreshTokens.store({
      userId: user.id,
      tokenHash: refresh.hash,
      userAgent: ctx.userAgent,
      ip: ctx.ip,
      expiresAt: refresh.expiresAt,
    });
    return {
      accessToken,
      refreshToken: refresh.raw,
      expiresIn: this.tokens.accessTtl,
      hasCharacter: hasCharacterHint ?? Boolean(characterId),
    };
  }
}
