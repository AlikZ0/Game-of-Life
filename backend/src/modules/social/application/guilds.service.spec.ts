import { GuildsService } from './guilds.service';

/**
 * Verifies the real-time side of guilds: chat messages are broadcast to the
 * guild room, and crediting weekly XP pushes a refreshed leaderboard.
 * Prisma + gateway are mocked.
 */
describe('GuildsService real-time', () => {
  const characterId = 'char_1';
  const guildId = 'guild_1';

  function build(member: { guildId: string } | null) {
    const realtime = {
      emitGuildMessage: jest.fn(),
      emitLeaderboardUpdate: jest.fn(),
    };
    const prisma = {
      guildMember: {
        findUnique: jest.fn().mockResolvedValue(member),
        update: jest.fn().mockResolvedValue({}),
        findMany: jest.fn().mockResolvedValue([
          {
            characterId,
            weeklyXp: 120,
            character: { id: characterId, name: 'Aria', level: 3 },
          },
        ]),
      },
      guild: { update: jest.fn().mockResolvedValue({}) },
      guildMessage: {
        create: jest.fn().mockResolvedValue({
          id: 'msg_1',
          body: 'gg',
          createdAt: new Date('2026-07-25T00:00:00Z'),
        }),
      },
      $transaction: jest.fn().mockResolvedValue([]),
    };
    const service = new GuildsService(prisma as never, realtime as never);
    return { service, realtime, prisma };
  }

  it('broadcasts a posted chat message to the guild room', async () => {
    const { service, realtime } = build({ guildId });
    await service.postMessage(characterId, guildId, { body: 'gg' });
    expect(realtime.emitGuildMessage).toHaveBeenCalledWith(
      guildId,
      expect.objectContaining({ characterId, body: 'gg' }),
    );
  });

  it('pushes a leaderboard update when weekly XP is credited', async () => {
    const { service, realtime } = build({ guildId });
    await service.recordWeeklyXp(characterId, 40);
    expect(realtime.emitLeaderboardUpdate).toHaveBeenCalledWith(
      guildId,
      expect.objectContaining({
        guildId,
        standings: expect.arrayContaining([
          expect.objectContaining({ rank: 1, characterId }),
        ]),
      }),
    );
  });

  it('is a no-op for a character not in a guild', async () => {
    const { service, realtime, prisma } = build(null);
    await service.recordWeeklyXp(characterId, 40);
    expect(prisma.guild.update).not.toHaveBeenCalled();
    expect(realtime.emitLeaderboardUpdate).not.toHaveBeenCalled();
  });
});
