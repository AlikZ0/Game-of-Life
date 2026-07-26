import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import {
  BillingProvider,
  SubscriptionStatus,
  SubscriptionTier,
} from '@prisma/client';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import {
  AppleReceiptVerifier,
  GoogleReceiptVerifier,
  ReceiptVerifier,
} from '../infrastructure/receipt-verifier';

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
    private readonly appleVerifier: AppleReceiptVerifier,
    private readonly googleVerifier: GoogleReceiptVerifier,
  ) {
    const key = this.config.get<string>('billing.stripeSecretKey');
    this.stripe = key
      ? new Stripe(key, { apiVersion: '2024-04-10' as Stripe.LatestApiVersion })
      : null;
  }

  /**
   * Redeem a mobile in-app-purchase receipt: verify it server-side with the
   * store, then upsert the user's subscription. An active receipt grants
   * Premium; an expired one drops the tier back to FREE.
   */
  async redeemReceipt(
    userId: string,
    provider: BillingProvider,
    receipt: string,
  ) {
    const verifier = this.verifierFor(provider);
    const verified = await verifier.verify(receipt);
    await this.upsert(userId, {
      provider: verified.provider,
      externalId: verified.externalId,
      tier: verified.isActive
        ? SubscriptionTier.PREMIUM
        : SubscriptionTier.FREE,
      status: verified.isActive
        ? SubscriptionStatus.ACTIVE
        : SubscriptionStatus.EXPIRED,
      currentPeriodEnd: verified.expiresAt ?? undefined,
    });
    return this.getStatus(userId);
  }

  private verifierFor(provider: BillingProvider): ReceiptVerifier {
    switch (provider) {
      case BillingProvider.APPLE_IAP:
        return this.appleVerifier;
      case BillingProvider.GOOGLE_PLAY:
        return this.googleVerifier;
      default:
        throw new BadRequestException(`Unsupported IAP provider: ${provider}`);
    }
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
      // Stamp the userId onto the Subscription object too, so the
      // customer.subscription.* / invoice.* events can be linked back to the
      // user directly instead of relying on event ordering.
      subscription_data: { metadata: { userId } },
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

    // Idempotency: Stripe redelivers until it sees a 2xx, so short-circuit any
    // event id we've already processed. Claiming the id up front (P2002 on a
    // concurrent redelivery → treat as duplicate) keeps handling exactly-once.
    try {
      await this.prisma.processedWebhookEvent.create({
        data: { id: event.id, provider: 'stripe', type: event.type },
      });
    } catch {
      this.logger.debug(`Duplicate Stripe event ignored: ${event.id}`);
      return { received: true, handled: false, duplicate: true };
    }

    await this.dispatch(event);
    return { received: true, handled: true };
  }

  /** Route a verified Stripe event to the right subscription mutation. */
  private async dispatch(event: Stripe.Event): Promise<void> {
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
      case 'customer.subscription.created':
      case 'customer.subscription.updated': {
        const sub = event.data.object as Stripe.Subscription;
        const status = this.mapStatus(sub.status);
        await this.applySubscription(sub, {
          // An active/trialing subscription keeps the user on Premium; any other
          // state (past_due, canceled, …) drops the tier back to FREE.
          tier:
            status === SubscriptionStatus.ACTIVE ||
            status === SubscriptionStatus.TRIALING
              ? SubscriptionTier.PREMIUM
              : SubscriptionTier.FREE,
          status,
          currentPeriodEnd: new Date(sub.current_period_end * 1000),
          cancelAtPeriodEnd: sub.cancel_at_period_end,
        });
        break;
      }
      case 'customer.subscription.deleted': {
        const sub = event.data.object as Stripe.Subscription;
        await this.applySubscription(sub, {
          tier: SubscriptionTier.FREE,
          status: SubscriptionStatus.CANCELLED,
          cancelAtPeriodEnd: false,
        });
        break;
      }
      case 'invoice.payment_succeeded': {
        // Recurring renewal: confirm Premium/ACTIVE and roll the period forward.
        const invoice = event.data.object as Stripe.Invoice;
        const externalId = this.subscriptionIdOf(invoice);
        if (externalId) {
          const periodEnd = invoice.lines?.data?.[0]?.period?.end;
          await this.upsertByExternalId(externalId, {
            tier: SubscriptionTier.PREMIUM,
            status: SubscriptionStatus.ACTIVE,
            currentPeriodEnd: periodEnd
              ? new Date(periodEnd * 1000)
              : undefined,
          });
        }
        break;
      }
      case 'invoice.payment_failed': {
        // A failed charge flags the subscription past-due; Stripe keeps retrying
        // and will send subscription.deleted if it ultimately gives up.
        const invoice = event.data.object as Stripe.Invoice;
        const externalId = this.subscriptionIdOf(invoice);
        if (externalId) {
          await this.upsertByExternalId(externalId, {
            status: SubscriptionStatus.PAST_DUE,
          });
        }
        break;
      }
      default:
        this.logger.debug(`Unhandled Stripe event: ${event.type}`);
    }
  }

  /** The subscription id carried by an invoice, when present. */
  private subscriptionIdOf(invoice: Stripe.Invoice): string | null {
    return typeof invoice.subscription === 'string'
      ? invoice.subscription
      : (invoice.subscription?.id ?? null);
  }

  /**
   * Persist a subscription-object change, preferring the userId stamped in the
   * Stripe subscription metadata (robust against event ordering) and falling
   * back to matching on the stored externalId.
   */
  private async applySubscription(
    sub: Stripe.Subscription,
    data: {
      tier?: SubscriptionTier;
      status?: SubscriptionStatus;
      currentPeriodEnd?: Date;
      cancelAtPeriodEnd?: boolean;
    },
  ): Promise<void> {
    const userId = sub.metadata?.userId;
    if (userId) {
      await this.upsert(userId, { ...data, externalId: sub.id });
      return;
    }
    await this.upsertByExternalId(sub.id, data);
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
      provider?: BillingProvider;
    },
  ) {
    const { provider = BillingProvider.STRIPE, ...rest } = data;
    return this.prisma.subscription.upsert({
      where: { userId },
      update: { ...rest, provider },
      create: {
        userId,
        provider,
        tier: rest.tier ?? SubscriptionTier.PREMIUM,
        status: rest.status ?? SubscriptionStatus.ACTIVE,
        externalId: rest.externalId,
        currentPeriodEnd: rest.currentPeriodEnd,
        cancelAtPeriodEnd: rest.cancelAtPeriodEnd ?? false,
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
