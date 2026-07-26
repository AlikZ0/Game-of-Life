import { SubscriptionStatus, SubscriptionTier } from '@prisma/client';
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
    return new SubscriptionService(prisma as never, config as never);
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
    const service = new SubscriptionService(prisma as never, config as never);
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
