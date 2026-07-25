import { Injectable, NotImplementedException } from '@nestjs/common';
import { BillingProvider } from '@prisma/client';

export interface VerifiedReceipt {
  provider: BillingProvider;
  /** Stable subscription/transaction id used as Subscription.externalId. */
  externalId: string;
  isActive: boolean;
  expiresAt: Date | null;
}

/**
 * Port for verifying mobile in-app-purchase receipts. The API accepts a receipt
 * from the app, verifies it server-side with the store, and upserts the user's
 * Subscription. Stripe (web) is handled separately in SubscriptionService.
 */
export const RECEIPT_VERIFIER = Symbol('RECEIPT_VERIFIER');

export interface ReceiptVerifier {
  provider: BillingProvider;
  verify(receipt: string): Promise<VerifiedReceipt>;
}

/**
 * Apple App Store receipt verification.
 * TODO: POST the receipt to https://buy.itunes.apple.com/verifyReceipt (with a
 * sandbox fallback on status 21007), validate the bundle id and the latest
 * `expires_date_ms`, and map it to a VerifiedReceipt.
 */
@Injectable()
export class AppleReceiptVerifier implements ReceiptVerifier {
  readonly provider = BillingProvider.APPLE_IAP;

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async verify(_receipt: string): Promise<VerifiedReceipt> {
    throw new NotImplementedException('Apple IAP verification not configured');
  }
}

/**
 * Google Play Billing receipt verification.
 * TODO: call the Android Publisher API
 * (purchases.subscriptions.get / subscriptionsv2) with a service account, check
 * `expiryTimeMillis` and acknowledgement state, and map it to a VerifiedReceipt.
 */
@Injectable()
export class GoogleReceiptVerifier implements ReceiptVerifier {
  readonly provider = BillingProvider.GOOGLE_PLAY;

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async verify(_receipt: string): Promise<VerifiedReceipt> {
    throw new NotImplementedException(
      'Google Play verification not configured',
    );
  }
}
