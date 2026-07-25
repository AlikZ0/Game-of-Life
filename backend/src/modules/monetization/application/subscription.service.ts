import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import {
  BillingProvider,
  SubscriptionStatus,
  SubscriptionTier,
} from '@prisma/client';
import { PrismaService } from '../../../infra/prisma/prisma.service';

export interface CheckoutResult {
  configured: boolean;
  url?: string;
  message?: string;
}

/**
 * Manages Premium subscriptions via Stripe Checkout + webhooks. Stripe is fully
 * optional: without `STRIPE_SECRET_KEY` the service returns a clear
 * "not configured" response and skips signature verification, so the API runs
 * end-to-end in local/CI environments with no billing credentials.
 */
@Injectable()
export class SubscriptionService {
  private readonly logger = new Logger(SubscriptionService.name);
  private readonly stripe: Stripe | null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    const key = this.config.get<string>('billing.stripeSecretKey');
    this.stripe = key
      ? new Stripe(key, { apiVersion: '2024-04-10' as Stripe.LatestApiVersion })
      : null;
  }

  /** Current subscription for a user (defaults to FREE / ACTIVE if none). */
  async getStatus(userId: string) {
    const sub = await this.prisma.subscription.findUnique({
      where: { userId },
    });
    return {
      tier: sub?.tier ?? SubscriptionTier.FREE,
      status: sub?.status ?? SubscriptionStatus.ACTIVE,
      currentPeriodEnd: sub?.currentPeriodEnd ?? null,
      cancelAtPeriodEnd: sub?.cancelAtPeriodEnd ?? false,
    };
  }

  /** True when the user holds an active Premium subscription. */
  async isPremium(userId: string): Promise<boolean> {
    const sub = await this.prisma.subscription.findUnique({
      where: { userId },
    });
    return (
      !!sub &&
      sub.tier === SubscriptionTier.PREMIUM &&
      (sub.status === SubscriptionStatus.ACTIVE ||
        sub.status === SubscriptionStatus.TRIALING)
    );
  }

  /**
   * Create a Stripe Checkout Session for the Premium plan and return its URL.
   * Falls back to a clear message when billing isn't configured.
   */
  async createCheckoutSession(
    userId: string,
    email: string,
  ): Promise<CheckoutResult> {
    if (!this.stripe) {
      return {
        configured: false,
        message: 'Billing is not configured on this environment',
      };
    }
    const priceId = this.config.get<string>('billing.stripePremiumPriceId');
    if (!priceId) {
      return {
        configured: false,
        message: 'Premium price is not configured',
      };
    }

    const session = await this.stripe.checkout.sessions.create({
      mode: 'subscription',
      customer_email: email,
      line_items: [{ price: priceId, quantity: 1 }],
      client_reference_id: userId,
      metadata: { userId },
      success_url: 'lifequest://billing/success',
      cancel_url: 'lifequest://billing/cancel',
    });

    return { configured: true, url: session.url ?? undefined };
  }

  /**
   * Handle a Stripe webhook. Verifies the signature when a webhook secret is
   * configured, then upserts the user's subscription for the relevant events.
   * Kept defensive so an unconfigured environment simply ignores the call.
   */
  async handleWebhook(rawBody: Buffer | string, signature?: string) {
    if (!this.stripe) {
      this.logger.warn(
        'Received webhook but Stripe is not configured — ignoring',
      );
      return { received: true, handled: false };
    }

    const secret = this.config.get<string>('billing.stripeWebhookSecret');
    let event: Stripe.Event;
    try {
      if (secret && signature) {
        event = this.stripe.webhooks.constructEvent(rawBody, signature, secret);
      } else {
        event = (
          typeof rawBody === 'string'
            ? JSON.parse(rawBody)
            : JSON.parse(rawBody.toString())
        ) as Stripe.Event;
      }
    } catch (err) {
      this.logger.error(
        `Webhook signature verification failed: ${String(err)}`,
      );
      return { received: true, handled: false };
    }

    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId =
          session.client_reference_id ?? session.metadata?.userId ?? null;
        if (userId) {
          await this.upsert(userId, {
            tier: SubscriptionTier.PREMIUM,
            status: SubscriptionStatus.ACTIVE,
            externalId:
              typeof session.subscription === 'string'
                ? session.subscription
                : undefined,
          });
        }
        break;
      }
      case 'customer.subscription.updated': {
        const sub = event.data.object as Stripe.Subscription;
        await this.upsertByExternalId(sub.id, {
          status: this.mapStatus(sub.status),
          currentPeriodEnd: new Date(sub.current_period_end * 1000),
          cancelAtPeriodEnd: sub.cancel_at_period_end,
        });
        break;
      }
      case 'customer.subscription.deleted': {
        const sub = event.data.object as Stripe.Subscription;
        await this.upsertByExternalId(sub.id, {
          tier: SubscriptionTier.FREE,
          status: SubscriptionStatus.CANCELLED,
        });
        break;
      }
      default:
        this.logger.debug(`Unhandled Stripe event: ${event.type}`);
    }

    return { received: true, handled: true };
  }

  private mapStatus(status: Stripe.Subscription.Status): SubscriptionStatus {
    switch (status) {
      case 'active':
        return SubscriptionStatus.ACTIVE;
      case 'trialing':
        return SubscriptionStatus.TRIALING;
      case 'past_due':
      case 'unpaid':
        return SubscriptionStatus.PAST_DUE;
      case 'canceled':
        return SubscriptionStatus.CANCELLED;
      default:
        return SubscriptionStatus.EXPIRED;
    }
  }

  private upsert(
    userId: string,
    data: {
      tier?: SubscriptionTier;
      status?: SubscriptionStatus;
      externalId?: string;
      currentPeriodEnd?: Date;
      cancelAtPeriodEnd?: boolean;
    },
  ) {
    return this.prisma.subscription.upsert({
      where: { userId },
      update: { ...data, provider: BillingProvider.STRIPE },
      create: {
        userId,
        provider: BillingProvider.STRIPE,
        tier: data.tier ?? SubscriptionTier.PREMIUM,
        status: data.status ?? SubscriptionStatus.ACTIVE,
        externalId: data.externalId,
        currentPeriodEnd: data.currentPeriodEnd,
        cancelAtPeriodEnd: data.cancelAtPeriodEnd ?? false,
      },
    });
  }

  private async upsertByExternalId(
    externalId: string,
    data: {
      tier?: SubscriptionTier;
      status?: SubscriptionStatus;
      currentPeriodEnd?: Date;
      cancelAtPeriodEnd?: boolean;
    },
  ) {
    const existing = await this.prisma.subscription.findFirst({
      where: { externalId },
    });
    if (!existing) {
      this.logger.warn(`No subscription found for external id ${externalId}`);
      return;
    }
    await this.prisma.subscription.update({
      where: { id: existing.id },
      data,
    });
  }
}
