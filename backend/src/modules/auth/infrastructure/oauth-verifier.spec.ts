import { UnauthorizedException } from '@nestjs/common';
import { jwtVerify } from 'jose';
import { OAuthVerifier } from './oauth-verifier';

// Mock jose so we drive verification results without real Apple keys/tokens.
jest.mock('jose', () => ({
  createRemoteJWKSet: jest.fn(() => 'APPLE_JWKS'),
  jwtVerify: jest.fn(),
}));

const jwtVerifyMock = jwtVerify as unknown as jest.Mock;

describe('OAuthVerifier.verifyApple', () => {
  const APPLE_AUD = 'com.lifequest.app';

  function build(appleClientId: string | undefined = APPLE_AUD) {
    const config = {
      get: jest.fn((key: string) =>
        key === 'oauth.appleClientId' ? appleClientId : undefined,
      ),
    };
    return new OAuthVerifier(config as never);
  }

  beforeEach(() => jwtVerifyMock.mockReset());

  it('verifies a valid token with issuer + audience and maps the profile', async () => {
    jwtVerifyMock.mockResolvedValue({
      payload: {
        sub: 'apple_123',
        email: 'hero@icloud.com',
        email_verified: 'true',
      },
    });

    const profile = await build().verifyApple('token');

    expect(profile).toEqual({
      providerId: 'apple_123',
      email: 'hero@icloud.com',
      emailVerified: true,
    });
    // Enforced the right issuer/audience against Apple's JWKS.
    expect(jwtVerifyMock).toHaveBeenCalledWith('token', 'APPLE_JWKS', {
      issuer: 'https://appleid.apple.com',
      audience: APPLE_AUD,
    });
  });

  it('accepts a boolean email_verified', async () => {
    jwtVerifyMock.mockResolvedValue({
      payload: { sub: 'apple_1', email: 'a@b.com', email_verified: true },
    });
    const profile = await build().verifyApple('token');
    expect(profile.emailVerified).toBe(true);
  });

  it('tolerates a missing email (repeat login)', async () => {
    jwtVerifyMock.mockResolvedValue({ payload: { sub: 'apple_1' } });
    const profile = await build().verifyApple('token');
    expect(profile.email).toBe('');
    expect(profile.providerId).toBe('apple_1');
  });

  it('rejects when Apple sign-in is not configured', async () => {
    // Empty client id → not configured (build(undefined) would hit the default).
    await expect(build('').verifyApple('token')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(jwtVerifyMock).not.toHaveBeenCalled();
  });

  it('rejects an invalid signature / claims', async () => {
    jwtVerifyMock.mockRejectedValue(new Error('signature verification failed'));
    await expect(build().verifyApple('bad')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('rejects a token without a subject', async () => {
    jwtVerifyMock.mockResolvedValue({ payload: { email: 'a@b.com' } });
    await expect(build().verifyApple('token')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
