import { Character, CharacterClass, Prisma } from '@prisma/client';

export const CHARACTER_REPOSITORY = Symbol('CHARACTER_REPOSITORY');

export interface CreateCharacterData {
  userId: string;
  name: string;
  avatarKey: string;
  characterClass: CharacterClass;
}

export interface CharacterRepository {
  findById(id: string): Promise<Character | null>;
  findByUserId(userId: string): Promise<Character | null>;
  create(data: CreateCharacterData): Promise<Character>;
  update(id: string, data: Prisma.CharacterUpdateInput): Promise<Character>;
  /** Runs a function inside a DB transaction (for atomic reward application). */
  transaction<T>(fn: (tx: Prisma.TransactionClient) => Promise<T>): Promise<T>;
}
