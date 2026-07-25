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
