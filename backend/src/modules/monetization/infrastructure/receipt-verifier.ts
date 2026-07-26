import {
  Injectable,
  Logger,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleAuth } from 'google-auth-library';
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

const APPLE_PROD_URL = 'https://buy.itunes.apple.com/verifyReceipt';
const APPLE_SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';
// Apple returns 21007 when a production receipt is actually from the sandbox —
// the documented signal to retry the same receipt against the sandbox host.
const APPLE_SANDBOX_STATUS = 21007;

interface AppleTransaction {
  original_transaction_id?: string;
  transaction_id?: string;
  expires_date_ms?: string;
}
interface AppleResponse {
  status: number;
  latest_receipt_info?: AppleTransaction[];
}

/**
 * Apple App Store receipt verification via /verifyReceipt. Optional: without an
 * `APPLE_SHARED_SECRET` the endpoint is unavailable rather than failing the
 * whole app at boot. Handles the sandbox-fallback handshake and picks the
 * latest transaction by expiry.
 */
@Injectable()
export class AppleReceiptVerifier implements ReceiptVerifier {
  readonly provider = BillingProvider.APPLE_IAP;
  private readonly logger = new Logger(AppleReceiptVerifier.name);

  constructor(private readonly config: ConfigService) {}

  async verify(receipt: string): Promise<VerifiedReceipt> {
    const sharedSecret = this.config.get<string>('billing.appleSharedSecret');
    if (!sharedSecret) {
      throw new ServiceUnavailableException(
        'Apple IAP verification is not configured',
      );
    }

    let res = await this.post(APPLE_PROD_URL, receipt, sharedSecret);
    if (res.status === APPLE_SANDBOX_STATUS) {
      res = await this.post(APPLE_SANDBOX_URL, receipt, sharedSecret);
    }
    if (res.status !== 0) {
      this.logger.warn(`Apple receipt rejected with status ${res.status}`);
      throw new UnauthorizedException('Invalid App Store receipt');
    }

    const latest = this.latestTransaction(res.latest_receipt_info ?? []);
    if (!latest?.expires_date_ms) {
      throw new UnauthorizedException('App Store receipt has no subscription');
    }
    const expiresAt = new Date(Number(latest.expires_date_ms));
    return {
      provider: this.provider,
      externalId:
        latest.original_transaction_id ?? latest.transaction_id ?? 'unknown',
      isActive: expiresAt.getTime() > Date.now(),
      expiresAt,
    };
  }

  private async post(
    url: string,
    receipt: string,
    password: string,
  ): Promise<AppleResponse> {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receipt,
        password,
        'exclude-old-transactions': true,
      }),
    });
    if (!res.ok) throw new ServiceUnavailableException('App Store unreachable');
    return (await res.json()) as AppleResponse;
  }

  private latestTransaction(txns: AppleTransaction[]): AppleTransaction | null {
    return txns.reduce<AppleTransaction | null>((latest, t) => {
      if (!t.expires_date_ms) return latest;
      if (!latest?.expires_date_ms) return t;
      return Number(t.expires_date_ms) > Number(latest.expires_date_ms)
        ? t
        : latest;
    }, null);
  }
}

interface GooglePurchase {
  expiryTimeMillis?: string;
  orderId?: string;
  paymentState?: number;
}

/**
 * Google Play Billing verification via the Android Publisher API. Optional:
 * requires a package name + service-account credentials, otherwise the endpoint
 * is unavailable. The client sends a JSON payload `{ productId, purchaseToken }`.
 */
@Injectable()
export class GoogleReceiptVerifier implements ReceiptVerifier {
  readonly provider = BillingProvider.GOOGLE_PLAY;
  private readonly logger = new Logger(GoogleReceiptVerifier.name);

  constructor(private readonly config: ConfigService) {}

  async verify(receipt: string): Promise<VerifiedReceipt> {
    const packageName = this.config.get<string>('billing.googlePackageName');
    if (!packageName || !this.hasCredentials()) {
      throw new ServiceUnavailableException(
        'Google Play verification is not configured',
      );
    }

    let productId: string;
    let purchaseToken: string;
    try {
      ({ productId, purchaseToken } = JSON.parse(receipt));
    } catch {
      throw new UnauthorizedException('Malformed Google Play receipt');
    }
    if (!productId || !purchaseToken) {
      throw new UnauthorizedException('Incomplete Google Play receipt');
    }

    const token = await this.fetchAccessToken();
    const url =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
      `${encodeURIComponent(packageName)}/purchases/subscriptions/` +
      `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

    const res = await fetch(url, {
      headers: { authorization: `Bearer ${token}` },
    });
    if (res.status === 401 || res.status === 404) {
      this.logger.warn(`Google receipt rejected with status ${res.status}`);
      throw new UnauthorizedException('Invalid Google Play receipt');
    }
    if (!res.ok) {
      throw new ServiceUnavailableException('Google Play unreachable');
    }

    const purchase = (await res.json()) as GooglePurchase;
    const expiresAt = purchase.expiryTimeMillis
      ? new Date(Number(purchase.expiryTimeMillis))
      : null;
    return {
      provider: this.provider,
      externalId: purchase.orderId ?? purchaseToken,
      isActive: !!expiresAt && expiresAt.getTime() > Date.now(),
      expiresAt,
    };
  }

  private hasCredentials(): boolean {
    return (
      !!this.config.get<string>('billing.googleServiceAccountEmail') &&
      !!this.config.get<string>('billing.googleServiceAccountKey')
    );
  }

  /**
   * Obtain an OAuth access token for the Android Publisher API from the
   * configured service account. Extracted so it can be stubbed in tests.
   */
  protected async fetchAccessToken(): Promise<string> {
    const auth = new GoogleAuth({
      credentials: {
        client_email: this.config.get<string>(
          'billing.googleServiceAccountEmail',
        ),
        private_key: this.config
          .get<string>('billing.googleServiceAccountKey')
          ?.replace(/\\n/g, '\n'),
      },
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
    const token = await auth.getAccessToken();
    if (!token) {
      throw new ServiceUnavailableException('Could not authenticate to Google');
    }
    return token;
  }
}
