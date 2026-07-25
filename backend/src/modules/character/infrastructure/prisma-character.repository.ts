import { Injectable } from '@nestjs/common';
import { Character, Prisma } from '@prisma/client';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import {
  CharacterRepository,
  CreateCharacterData,
} from '../domain/character.repository';

@Injectable()
export class PrismaCharacterRepository implements CharacterRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<Character | null> {
    return this.prisma.character.findUnique({ where: { id } });
  }

  findByUserId(userId: string): Promise<Character | null> {
    return this.prisma.character.findUnique({ where: { userId } });
  }

  create(data: CreateCharacterData): Promise<Character> {
    return this.prisma.character.create({ data });
  }

  update(id: string, data: Prisma.CharacterUpdateInput): Promise<Character> {
    return this.prisma.character.update({ where: { id }, data });
  }

  transaction<T>(fn: (tx: Prisma.TransactionClient) => Promise<T>): Promise<T> {
    return this.prisma.$transaction(fn);
  }
}
