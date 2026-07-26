import {
  BillingProvider,
  SubscriptionStatus,
  SubscriptionTier,
} from '@prisma/client';
import { SubscriptionService } from './subscription.service';

/**
 * Premium entitlement rules — the single gate that unlocks LLM coaching,
 * advanced analytics, exclusive themes, etc. Prisma + config are mocked.
 */
describe('SubscriptionService.isPremium', () => {
  function build(sub: Record<string, unknown> | null) {
    const prisma = {
      subscription: { findUnique: jest.fn().mockResolvedValue(sub) },
    };
    const config = { get: jest.fn().mockReturnValue(undefined) };
    return new SubscriptionService(
      prisma as never,
      config as never,
      {} as never,
      {} as never,
    );
  }

  it('is true for an active Premium subscription', async () => {
    const svc = build({
      tier: SubscriptionTier.PREMIUM,
      status: SubscriptionStatus.ACTIVE,
    });
    await expect(svc.isPremium('u1')).resolves.toBe(true);
  });

  it('is true while trialing Premium', async () => {
    const svc = build({
      tier: SubscriptionTier.PREMIUM,
      status: SubscriptionStatus.TRIALING,
    });
    await expect(svc.isPremium('u1')).resolves.toBe(true);
  });

  it('is false for a free user', async () => {
    const svc = build({
      tier: SubscriptionTier.FREE,
      status: SubscriptionStatus.ACTIVE,
    });
    await expect(svc.isPremium('u1')).resolves.toBe(false);
  });

  it('is false for a cancelled/expired Premium subscription', async () => {
    const svc = build({
      tier: SubscriptionTier.PREMIUM,
      status: SubscriptionStatus.CANCELLED,
    });
    await expect(svc.isPremium('u1')).resolves.toBe(false);
  });

  it('is false when the user has no subscription record', async () => {
    const svc = build(null);
    await expect(svc.isPremium('u1')).resolves.toBe(false);
  });
});

/**
 * Stripe webhook handling: dispatch of the full subscription lifecycle plus
 * exactly-once idempotency. Stripe runs in "no signature secret" mode so the
 * raw JSON body is parsed directly (no real API calls).
 */
describe('SubscriptionService.handleWebhook', () => {
  function build(opts: { existing?: { id: string } | null; seen?: boolean }) {
    const created = { throws: opts.seen ?? false };
    const prisma = {
      subscription: {
        upsert: jest.fn().mockResolvedValue({}),
        update: jest.fn().mockResolvedValue({}),
        findFirst: jest
          .fn()
          .mockResolvedValue(opts.existing ?? { id: 'sub_row' }),
      },
      processedWebhookEvent: {
        create: jest
          .fn()
          .mockImplementation(() =>
            created.throws
              ? Promise.reject(new Error('unique'))
              : Promise.resolve({}),
          ),
      },
    };
    const config = {
      get: jest.fn((k: string) =>
        k === 'billing.stripeSecretKey' ? 'sk_test_x' : undefined,
      ),
    };
    const service = new SubscriptionService(
      prisma as never,
      config as never,
      {} as never,
      {} as never,
    );
    return { service, prisma };
  }

  const send = (service: SubscriptionService, event: object) =>
    service.handleWebhook(JSON.stringify(event));

  it('marks a completed checkout as active Premium', async () => {
    const { service, prisma } = build({});
    const res = await send(service, {
      id: 'evt_1',
      type: 'checkout.session.completed',
      data: { object: { client_reference_id: 'u1', subscription: 'sub_1' } },
    });
    expect(res).toMatchObject({ received: true, handled: true });
    expect(prisma.subscription.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId: 'u1' } }),
    );
  });

  it('links subscription.updated via metadata userId and rolls the period', async () => {
    const { service, prisma } = build({});
    await send(service, {
      id: 'evt_2',
      type: 'customer.subscription.updated',
      data: {
        object: {
          id: 'sub_1',
          status: 'active',
          current_period_end: 1900000000,
          cancel_at_period_end: false,
          metadata: { userId: 'u1' },
        },
      },
    });
    expect(prisma.subscription.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'u1' },
        update: expect.objectContaining({ externalId: 'sub_1' }),
      }),
    );
  });

  it('drops the tier to FREE on a canceled subscription.updated', async () => {
    const { service, prisma } = build({});
    await send(service, {
      id: 'evt_3',
      type: 'customer.subscription.updated',
      data: {
        object: {
          id: 'sub_1',
          status: 'canceled',
          current_period_end: 1900000000,
          cancel_at_period_end: true,
          metadata: { userId: 'u1' },
        },
      },
    });
    const call = prisma.subscription.upsert.mock.calls[0][0];
    expect(call.update.tier).toBe(SubscriptionTier.FREE);
    expect(call.update.status).toBe(SubscriptionStatus.CANCELLED);
  });

  it('renews on invoice.payment_succeeded (external id match)', async () => {
    const { service, prisma } = build({ existing: { id: 'sub_row' } });
    await send(service, {
      id: 'evt_4',
      type: 'invoice.payment_succeeded',
      data: {
        object: {
          subscription: 'sub_1',
          lines: { data: [{ period: { end: 1900000000 } }] },
        },
      },
    });
    expect(prisma.subscription.findFirst).toHaveBeenCalledWith({
      where: { externalId: 'sub_1' },
    });
    expect(prisma.subscription.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'sub_row' },
        data: expect.objectContaining({ status: SubscriptionStatus.ACTIVE }),
      }),
    );
  });

  it('flags past-due on invoice.payment_failed', async () => {
    const { service, prisma } = build({ existing: { id: 'sub_row' } });
    await send(service, {
      id: 'evt_5',
      type: 'invoice.payment_failed',
      data: { object: { subscription: 'sub_1' } },
    });
    expect(prisma.subscription.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { status: SubscriptionStatus.PAST_DUE },
      }),
    );
  });

  it('short-circuits a redelivered (duplicate) event without dispatching', async () => {
    const { service, prisma } = build({ seen: true });
    const res = await send(service, {
      id: 'evt_1',
      type: 'checkout.session.completed',
      data: { object: { client_reference_id: 'u1' } },
    });
    expect(res).toMatchObject({ handled: false, duplicate: true });
    expect(prisma.subscription.upsert).not.toHaveBeenCalled();
  });
});

/**
 * Mobile IAP redemption: verify a store receipt, then grant/revoke Premium.
 */
describe('SubscriptionService.redeemReceipt', () => {
  function build(verified: {
    provider: BillingProvider;
    externalId: string;
    isActive: boolean;
    expiresAt: Date | null;
  }) {
    const prisma = {
      subscription: {
        upsert: jest.fn().mockResolvedValue({}),
        findUnique: jest.fn().mockResolvedValue({
          tier: verified.isActive
            ? SubscriptionTier.PREMIUM
            : SubscriptionTier.FREE,
          status: verified.isActive
            ? SubscriptionStatus.ACTIVE
            : SubscriptionStatus.EXPIRED,
          currentPeriodEnd: verified.expiresAt,
          cancelAtPeriodEnd: false,
        }),
      },
    };
    const config = { get: jest.fn().mockReturnValue(undefined) };
    const apple = { verify: jest.fn().mockResolvedValue(verified) };
    const google = { verify: jest.fn().mockResolvedValue(verified) };
    const service = new SubscriptionService(
      prisma as never,
      config as never,
      apple as never,
      google as never,
    );
    return { service, prisma, apple, google };
  }

  it('grants Premium for an active Apple receipt', async () => {
    const { service, prisma, apple } = build({
      provider: BillingProvider.APPLE_IAP,
      externalId: 'o1',
      isActive: true,
      expiresAt: new Date('2099-01-01'),
    });
    const status = await service.redeemReceipt(
      'u1',
      BillingProvider.APPLE_IAP,
      'receipt',
    );
    expect(apple.verify).toHaveBeenCalledWith('receipt');
    expect(prisma.subscription.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'u1' },
        update: expect.objectContaining({
          provider: BillingProvider.APPLE_IAP,
          tier: SubscriptionTier.PREMIUM,
          status: SubscriptionStatus.ACTIVE,
          externalId: 'o1',
        }),
      }),
    );
    expect(status.tier).toBe(SubscriptionTier.PREMIUM);
  });

  it('routes Google receipts to the Google verifier', async () => {
    const { service, apple, google } = build({
      provider: BillingProvider.GOOGLE_PLAY,
      externalId: 'GPA.1',
      isActive: true,
      expiresAt: new Date('2099-01-01'),
    });
    await service.redeemReceipt('u1', BillingProvider.GOOGLE_PLAY, 'r');
    expect(google.verify).toHaveBeenCalled();
    expect(apple.verify).not.toHaveBeenCalled();
  });

  it('drops the tier to FREE for an expired receipt', async () => {
    const { service, prisma } = build({
      provider: BillingProvider.APPLE_IAP,
      externalId: 'o1',
      isActive: false,
      expiresAt: new Date('2000-01-01'),
    });
    await service.redeemReceipt('u1', BillingProvider.APPLE_IAP, 'r');
    expect(prisma.subscription.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        update: expect.objectContaining({
          tier: SubscriptionTier.FREE,
          status: SubscriptionStatus.EXPIRED,
        }),
      }),
    );
  });

  it('rejects an unsupported provider (e.g. Stripe) for IAP', async () => {
    const { service } = build({
      provider: BillingProvider.APPLE_IAP,
      externalId: 'o1',
      isActive: true,
      expiresAt: null,
    });
    await expect(
      service.redeemReceipt('u1', BillingProvider.STRIPE, 'r'),
    ).rejects.toThrow();
  });
});
