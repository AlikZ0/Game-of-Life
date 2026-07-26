import {
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { BillingProvider } from '@prisma/client';
import {
  AppleReceiptVerifier,
  GoogleReceiptVerifier,
} from './receipt-verifier';

const cfg = (map: Record<string, string | undefined>) => ({
  get: jest.fn((k: string) => map[k]),
});

describe('AppleReceiptVerifier', () => {
  const realFetch = global.fetch;
  afterEach(() => {
    global.fetch = realFetch;
    jest.restoreAllMocks();
  });

  const future = String(Date.now() + 86_400_000);

  it('is unavailable without a shared secret', async () => {
    const v = new AppleReceiptVerifier(cfg({}) as never);
    await expect(v.verify('r')).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('verifies a valid receipt and picks the latest transaction', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        status: 0,
        latest_receipt_info: [
          { original_transaction_id: 'o1', expires_date_ms: '1000' },
          { original_transaction_id: 'o1', expires_date_ms: future },
        ],
      }),
    }) as never;

    const v = new AppleReceiptVerifier(
      cfg({ 'billing.appleSharedSecret': 'secret' }) as never,
    );
    const res = await v.verify('r');
    expect(res).toMatchObject({
      provider: BillingProvider.APPLE_IAP,
      externalId: 'o1',
      isActive: true,
    });
    expect(res.expiresAt?.getTime()).toBe(Number(future));
  });

  it('retries against the sandbox on status 21007', async () => {
    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ status: 21007 }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          status: 0,
          latest_receipt_info: [
            { original_transaction_id: 'sandbox1', expires_date_ms: future },
          ],
        }),
      });
    global.fetch = fetchMock as never;

    const v = new AppleReceiptVerifier(
      cfg({ 'billing.appleSharedSecret': 'secret' }) as never,
    );
    const res = await v.verify('r');
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock.mock.calls[1][0]).toContain('sandbox');
    expect(res.externalId).toBe('sandbox1');
  });

  it('rejects a receipt Apple reports as invalid', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ status: 21002 }),
    }) as never;
    const v = new AppleReceiptVerifier(
      cfg({ 'billing.appleSharedSecret': 'secret' }) as never,
    );
    await expect(v.verify('r')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});

// Test subclass that stubs the OAuth token acquisition (no real Google auth).
class TestableGoogleVerifier extends GoogleReceiptVerifier {
  protected async fetchAccessToken(): Promise<string> {
    return 'access-token';
  }
}

describe('GoogleReceiptVerifier', () => {
  const realFetch = global.fetch;
  afterEach(() => {
    global.fetch = realFetch;
    jest.restoreAllMocks();
  });

  const fullCfg = cfg({
    'billing.googlePackageName': 'app.lifequest',
    'billing.googleServiceAccountEmail': 'sa@lifequest.iam',
    'billing.googleServiceAccountKey': 'key',
  });
  const future = String(Date.now() + 86_400_000);
  const receipt = JSON.stringify({
    productId: 'premium',
    purchaseToken: 'tok',
  });

  it('is unavailable without package + credentials', async () => {
    const v = new TestableGoogleVerifier(cfg({}) as never);
    await expect(v.verify(receipt)).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('rejects a malformed receipt payload', async () => {
    const v = new TestableGoogleVerifier(fullCfg as never);
    await expect(v.verify('not-json')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('verifies an active subscription', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ expiryTimeMillis: future, orderId: 'GPA.1' }),
    }) as never;

    const v = new TestableGoogleVerifier(fullCfg as never);
    const res = await v.verify(receipt);
    expect(res).toMatchObject({
      provider: BillingProvider.GOOGLE_PLAY,
      externalId: 'GPA.1',
      isActive: true,
    });
    const [url, init] = (global.fetch as jest.Mock).mock.calls[0];
    expect(url).toContain('androidpublisher.googleapis.com');
    expect(init.headers.authorization).toBe('Bearer access-token');
  });

  it('rejects when Google returns 404 (invalid token)', async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValue({ ok: false, status: 404 }) as never;
    const v = new TestableGoogleVerifier(fullCfg as never);
    await expect(v.verify(receipt)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
