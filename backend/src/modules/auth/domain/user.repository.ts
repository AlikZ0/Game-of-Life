import { AuthProvider, User } from '@prisma/client';

/** Port (interface) for user persistence — implemented in the infra layer. */
export const USER_REPOSITORY = Symbol('USER_REPOSITORY');

export interface CreateUserData {
  email: string;
  passwordHash?: string;
  provider: AuthProvider;
  providerId?: string;
  emailVerified?: boolean;
}

export interface UserRepository {
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  findByProvider(
    provider: AuthProvider,
    providerId: string,
  ): Promise<User | null>;
  create(data: CreateUserData): Promise<User>;
  markLoggedIn(id: string): Promise<void>;
}
