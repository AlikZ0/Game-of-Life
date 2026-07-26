import { ReminderService } from './reminder.service';
import { periodKeyFor } from '../../../common/utils/period';

describe('ReminderService', () => {
  const now = new Date('2026-07-26T18:00:00Z');

  function build(rows: Array<{ character: { userId: string } }>) {
    const prisma = {
      quest: { findMany: jest.fn().mockResolvedValue(rows) },
    };
    const notifications = { send: jest.fn().mockResolvedValue(undefined) };
    return {
      service: new ReminderService(prisma as never, notifications as never),
      prisma,
      notifications,
    };
  }

  it('selects distinct users with an incomplete daily quest and a device', async () => {
    const { service, prisma } = build([
      { character: { userId: 'u1' } },
      { character: { userId: 'u2' } },
      { character: { userId: 'u1' } },
    ]);

    const users = await service.usersNeedingReminder(now);

    expect(users).toEqual(['u1', 'u2']);
    expect(prisma.quest.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          status: 'ACTIVE',
          cadence: 'DAILY',
          completions: { none: { periodKey: periodKeyFor('DAILY', now) } },
          character: { user: { notificationTokens: { some: {} } } },
        }),
        distinct: ['characterId'],
      }),
    );
  });

  it('pushes a reminder to each selected user', async () => {
    const { service, notifications } = build([{ character: { userId: 'u1' } }]);
    await service.sendDailyReminders();
    expect(notifications.send).toHaveBeenCalledWith(
      'u1',
      expect.objectContaining({ data: { type: 'daily_reminder' } }),
    );
  });

  it('sends nothing when no one needs a reminder', async () => {
    const { service, notifications } = build([]);
    await service.sendDailyReminders();
    expect(notifications.send).not.toHaveBeenCalled();
  });
});
