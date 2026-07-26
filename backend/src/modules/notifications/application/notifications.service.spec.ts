import { NotificationsService } from './notifications.service';

describe('NotificationsService.send', () => {
  function build(opts: {
    tokens: string[];
    enabled: boolean;
    dead?: string[];
  }) {
    const prisma = {
      notificationToken: {
        findMany: jest
          .fn()
          .mockResolvedValue(opts.tokens.map((fcmToken) => ({ fcmToken }))),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
    };
    const fcm = {
      enabled: opts.enabled,
      sendMulticast: jest.fn().mockResolvedValue(opts.dead ?? []),
    };
    return {
      service: new NotificationsService(prisma as never, fcm as never),
      prisma,
      fcm,
    };
  }

  it('does nothing when the user has no registered devices', async () => {
    const { service, fcm } = build({ tokens: [], enabled: true });
    await service.send('u1', { title: 'hi', body: 'there' });
    expect(fcm.sendMulticast).not.toHaveBeenCalled();
  });

  it('is a no-op (no dispatch) when Firebase is not configured', async () => {
    const { service, fcm } = build({ tokens: ['t1'], enabled: false });
    await service.send('u1', { title: 'hi', body: 'there' });
    expect(fcm.sendMulticast).not.toHaveBeenCalled();
  });

  it('dispatches to every device token when enabled', async () => {
    const { service, fcm, prisma } = build({
      tokens: ['t1', 't2'],
      enabled: true,
    });
    await service.send('u1', { title: 'hi', body: 'there' });
    expect(fcm.sendMulticast).toHaveBeenCalledWith(
      ['t1', 't2'],
      expect.objectContaining({ title: 'hi' }),
    );
    expect(prisma.notificationToken.deleteMany).not.toHaveBeenCalled();
  });

  it('prunes tokens FCM reports as dead', async () => {
    const { service, prisma } = build({
      tokens: ['t1', 't2'],
      enabled: true,
      dead: ['t2'],
    });
    await service.send('u1', { title: 'hi', body: 'there' });
    expect(prisma.notificationToken.deleteMany).toHaveBeenCalledWith({
      where: { fcmToken: { in: ['t2'] } },
    });
  });
});
