import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { AuthProvider } from '@prisma/client';
import { AuthService } from './auth.service';

/**
 * The authentication use cases: credential + OAuth sign-in, and — most
 * security-sensitive — refresh-token rotation. All ports/infrastructure are
 * mocked so the coordination logic is exercised in isolation.
 */
describe('AuthService', () => {
  const ctx = { userAgent: 'jest', ip: '127.0.0.1' };

  function build(
    overrides: {
      userByEmail?: unknown;
      userById?: unknown;
      userByProvider?: unknown;
      verifyPassword?: boolean;
      validRefresh?: { id: string; userId: string } | null;
      oauthProfile?: {
        providerId: string;
        email: string;
        emailVerified: boolean;
      };
    } = {},
  ) {
    const users = {
      findByEmail: jest.fn().mockResolvedValue(overrides.userByEmail ?? null),
      findById: jest.fn().mockResolvedValue(overrides.userById ?? null),
      findByProvider: jest
        .fn()
        .mockResolvedValue(overrides.userByProvider ?? null),
      create: jest.fn().mockImplementation(({ email, provider, providerId }) =>
        Promise.resolve({
          id: 'u-new',
          email,
          provider,
          providerId,
          character: null,
        }),
      ),
      markLoggedIn: jest.fn().mockResolvedValue(undefined),
    };
    const refreshTokens = {
      findValidByHash: jest
        .fn()
        .mockResolvedValue(
          overrides.validRefresh === undefined ? null : overrides.validRefresh,
        ),
      revoke: jest.fn().mockResolvedValue(undefined),
      store: jest.fn().mockResolvedValue(undefined),
    };
    const hasher = {
      hash: jest.fn().mockResolvedValue('hashed-pw'),
      verify: jest.fn().mockResolvedValue(overrides.verifyPassword ?? true),
    };
    const tokens = {
      accessTtl: 900,
      signAccessToken: jest.fn().mockResolvedValue('access-jwt'),
      generateRefreshToken: jest.fn().mockReturnValue({
        raw: 'raw-refresh',
        hash: 'refresh-hash',
        expiresAt: new Date('2099-01-01'),
      }),
      hashRefresh: jest.fn((raw: string) => `hash:${raw}`),
    };
    const oauth = {
      verifyGoogle: jest.fn().mockResolvedValue(
        overrides.oauthProfile ?? {
          providerId: 'g-123',
          email: 'g@lifequest.app',
          emailVerified: true,
        },
      ),
      verifyApple: jest.fn().mockResolvedValue(
        overrides.oauthProfile ?? {
          providerId: 'a-123',
          email: '',
          emailVerified: false,
        },
      ),
    };
    const service = new AuthService(
      users as never,
      refreshTokens as never,
      hasher as never,
      tokens as never,
      oauth as never,
    );
    return { service, users, refreshTokens, hasher, tokens, oauth };
  }

  // ── register ────────────────────────────────────────────
  describe('register', () => {
    it('rejects a duplicate email without creating a user', async () => {
      const { service, users } = build({ userByEmail: { id: 'u1' } });
      await expect(
        service.register('a@b.co', 'pw', ctx),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(users.create).not.toHaveBeenCalled();
    });

    it('hashes the password, creates the account and issues tokens', async () => {
      const { service, users, hasher, refreshTokens } = build();
      const res = await service.register('a@b.co', 'Str0ng!', ctx);

      expect(hasher.hash).toHaveBeenCalledWith('Str0ng!');
      expect(users.create).toHaveBeenCalledWith(
        expect.objectContaining({
          email: 'a@b.co',
          passwordHash: 'hashed-pw',
          provider: AuthProvider.EMAIL,
        }),
      );
      expect(res).toMatchObject({
        accessToken: 'access-jwt',
        refreshToken: 'raw-refresh',
        expiresIn: 900,
        hasCharacter: false,
      });
      // the refresh token is persisted (hashed), never the raw value
      expect(refreshTokens.store).toHaveBeenCalledWith(
        expect.objectContaining({ tokenHash: 'refresh-hash' }),
      );
    });
  });

  // ── login ───────────────────────────────────────────────
  describe('login', () => {
    it('rejects an unknown email', async () => {
      const { service } = build({ userByEmail: null });
      await expect(service.login('x@y.z', 'pw', ctx)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('rejects a wrong password', async () => {
      const { service } = build({
        userByEmail: { id: 'u1', passwordHash: 'h' },
        verifyPassword: false,
      });
      await expect(service.login('x@y.z', 'pw', ctx)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('issues tokens and stamps last-login on success', async () => {
      const { service, users } = build({
        userByEmail: { id: 'u1', email: 'x@y.z', passwordHash: 'h' },
        verifyPassword: true,
      });
      const res = await service.login('x@y.z', 'pw', ctx);
      expect(users.markLoggedIn).toHaveBeenCalledWith('u1');
      expect(res.accessToken).toBe('access-jwt');
    });
  });

  // ── refresh rotation (security-critical) ─────────────────
  describe('refresh', () => {
    it('rejects an unknown/expired refresh token', async () => {
      const { service } = build({ validRefresh: null });
      await expect(service.refresh('raw', ctx)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('rotates: revokes the used token and issues a fresh pair', async () => {
      const { service, refreshTokens, users } = build({
        validRefresh: { id: 'rt1', userId: 'u1' },
        userById: { id: 'u1', email: 'x@y.z', character: null },
      });
      const res = await service.refresh('raw', ctx);

      // the presented token is revoked (single-use rotation)
      expect(refreshTokens.revoke).toHaveBeenCalledWith('rt1');
      expect(users.findById).toHaveBeenCalledWith('u1');
      // and a brand-new refresh token is stored
      expect(refreshTokens.store).toHaveBeenCalledTimes(1);
      expect(res.refreshToken).toBe('raw-refresh');
    });

    it('rejects when the token is valid but the user is gone', async () => {
      const { service, refreshTokens } = build({
        validRefresh: { id: 'rt1', userId: 'ghost' },
        userById: null,
      });
      await expect(service.refresh('raw', ctx)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      // still revoked the presented token before bailing
      expect(refreshTokens.revoke).toHaveBeenCalledWith('rt1');
    });
  });

  // ── logout ──────────────────────────────────────────────
  describe('logout', () => {
    it('revokes a known refresh token', async () => {
      const { service, refreshTokens } = build({
        validRefresh: { id: 'rt1', userId: 'u1' },
      });
      await service.logout('raw');
      expect(refreshTokens.revoke).toHaveBeenCalledWith('rt1');
    });

    it('is a no-op for an unknown token', async () => {
      const { service, refreshTokens } = build({ validRefresh: null });
      await service.logout('raw');
      expect(refreshTokens.revoke).not.toHaveBeenCalled();
    });
  });

  // ── OAuth upsert ─────────────────────────────────────────
  describe('OAuth sign-in', () => {
    it('reuses an existing provider-linked account without creating', async () => {
      const { service, users } = build({
        userByProvider: { id: 'u1', email: 'g@lifequest.app', character: null },
      });
      await service.loginWithGoogle('idtoken', ctx);
      expect(users.create).not.toHaveBeenCalled();
      expect(users.markLoggedIn).toHaveBeenCalledWith('u1');
    });

    it('creates a new account for a first-time Google user', async () => {
      const { service, users } = build({
        userByProvider: null,
        userByEmail: null,
        oauthProfile: {
          providerId: 'g-9',
          email: 'new@lifequest.app',
          emailVerified: true,
        },
      });
      await service.loginWithGoogle('idtoken', ctx);
      expect(users.create).toHaveBeenCalledWith(
        expect.objectContaining({
          email: 'new@lifequest.app',
          provider: AuthProvider.GOOGLE,
          providerId: 'g-9',
        }),
      );
    });

    it('links to an existing email account instead of duplicating it', async () => {
      const { service, users } = build({
        userByProvider: null,
        userByEmail: {
          id: 'u-existing',
          email: 'same@lifequest.app',
          character: null,
        },
        oauthProfile: {
          providerId: 'g-9',
          email: 'same@lifequest.app',
          emailVerified: true,
        },
      });
      await service.loginWithGoogle('idtoken', ctx);
      expect(users.create).not.toHaveBeenCalled();
      expect(users.markLoggedIn).toHaveBeenCalledWith('u-existing');
    });

    it('falls back to a private-relay email when Apple omits it', async () => {
      const { service, users } = build({
        userByProvider: null,
        oauthProfile: { providerId: 'a-9', email: '', emailVerified: false },
      });
      await service.loginWithApple('idtoken', ctx);
      expect(users.create).toHaveBeenCalledWith(
        expect.objectContaining({
          email: 'a-9@privaterelay.appleid.com',
          provider: AuthProvider.APPLE,
        }),
      );
    });
  });
});
