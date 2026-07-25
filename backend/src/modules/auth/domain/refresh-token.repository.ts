import { RefreshToken } from '@prisma/client';

export const REFRESH_TOKEN_REPOSITORY = Symbol('REFRESH_TOKEN_REPOSITORY');

export interface StoreRefreshTokenData {
  userId: string;
  tokenHash: string;
  userAgent?: string;
  ip?: string;
  expiresAt: Date;
}

export interface RefreshTokenRepository {
  store(data: StoreRefreshTokenData): Promise<RefreshToken>;
  findValidByHash(tokenHash: string): Promise<RefreshToken | null>;
  revoke(id: string): Promise<void>;
  revokeAllForUser(userId: string): Promise<void>;
}
