import { PvpMetric } from '@prisma/client';
import { GuildsService } from './guilds.service';

/**
 * Verifies the real-time side of guilds: chat broadcast, leaderboard push, and
 * shared-mission auto-progress + completion rewards. Prisma / gateway /
 * character service are mocked.
 */
describe('GuildsService real-time', () => {
  const characterId = 'char_1';
  const guildId = 'guild_1';

  function build(
    member: { guildId: string } | null,
    missions: unknown[] = [],
    missionUpdateCount = 1,
  ) {
    const realtime = {
      emitGuildMessage: jest.fn(),
      emitLeaderboardUpdate: jest.fn(),
    };
    const characters = { awardRewards: jest.fn().mockResolvedValue({}) };
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
      guildMission: {
        findMany: jest.fn().mockResolvedValue(missions),
        updateMany: jest.fn().mockResolvedValue({ count: missionUpdateCount }),
      },
      guildMessage: {
        create: jest.fn().mockResolvedValue({
          id: 'msg_1',
          body: 'gg',
          createdAt: new Date('2026-07-25T00:00:00Z'),
        }),
      },
      $transaction: jest.fn().mockResolvedValue([]),
    };
    const service = new GuildsService(
      prisma as never,
      realtime as never,
      characters as never,
    );
    return { service, realtime, prisma, characters };
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

  it('advances an active mission without completing it', async () => {
    const { service, prisma, characters } = build(null, [
      { id: 'm1', currentValue: 100, targetValue: 1000, rewardGold: 500 },
    ]);
    await service.advanceMissions(guildId, PvpMetric.XP, 40);
    expect(prisma.guildMission.updateMany).toHaveBeenCalledWith({
      where: { id: 'm1', completedAt: null },
      data: { currentValue: 140, completedAt: null },
    });
    expect(characters.awardRewards).not.toHaveBeenCalled();
  });

  it('completes a mission at target and rewards every member', async () => {
    const { service, prisma, characters } = build(null, [
      { id: 'm1', currentValue: 970, targetValue: 1000, rewardGold: 500 },
    ]);
    await service.advanceMissions(guildId, PvpMetric.XP, 40);
    // completedAt stamped
    expect(prisma.guildMission.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ currentValue: 1010 }),
      }),
    );
    const call = prisma.guildMission.updateMany.mock.calls[0][0];
    expect(call.data.completedAt).toBeInstanceOf(Date);
    // reward granted to the (one) member returned by findMany
    expect(characters.awardRewards).toHaveBeenCalledWith(
      expect.objectContaining({ gold: 500, characterId }),
    );
  });

  it('ignores non-positive mission progress', async () => {
    const { service, prisma } = build(null, []);
    await service.advanceMissions(guildId, PvpMetric.XP, 0);
    expect(prisma.guildMission.findMany).not.toHaveBeenCalled();
  });

  it('feeds a non-XP activity signal into that metric’s missions', async () => {
    const { service, prisma } = build({ guildId }, [
      {
        id: 'm1',
        currentValue: 2,
        targetValue: 10,
        rewardGold: 0,
        metric: PvpMetric.QUESTS_COMPLETED,
      },
    ]);
    await service.recordActivity(characterId, PvpMetric.QUESTS_COMPLETED, 1);
    expect(prisma.guildMission.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          guildId,
          metric: PvpMetric.QUESTS_COMPLETED,
          completedAt: null,
        }),
      }),
    );
    expect(prisma.guildMission.updateMany).toHaveBeenCalledWith({
      where: { id: 'm1', completedAt: null },
      data: { currentValue: 3, completedAt: null },
    });
  });

  it('recordActivity is a no-op for a character not in a guild', async () => {
    const { service, prisma } = build(null);
    await service.recordActivity(characterId, PvpMetric.QUESTS_COMPLETED, 1);
    expect(prisma.guildMission.findMany).not.toHaveBeenCalled();
  });
});
