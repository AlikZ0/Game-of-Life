import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsString, MaxLength, MinLength } from 'class-validator';
import { BillingProvider } from '@prisma/client';

/** Mobile stores are the only IAP providers; Stripe uses the web checkout flow. */
export type IapProvider =
  typeof BillingProvider.APPLE_IAP | typeof BillingProvider.GOOGLE_PLAY;

export class RedeemReceiptDto {
  @ApiProperty({
    enum: [BillingProvider.APPLE_IAP, BillingProvider.GOOGLE_PLAY],
    example: BillingProvider.APPLE_IAP,
  })
  @IsEnum(BillingProvider)
  provider!: BillingProvider;

  @ApiProperty({
    description:
      'Apple: base64 receipt-data. Google: JSON `{ productId, purchaseToken }`.',
  })
  @IsString()
  @MinLength(1)
  @MaxLength(20000)
  receipt!: string;
}
