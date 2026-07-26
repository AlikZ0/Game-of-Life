import { Body, Controller, Get, Headers, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { Public } from '../../../common/decorators/public.decorator';
import { RedeemReceiptDto } from '../application/dto/redeem-receipt.dto';
import { SubscriptionService } from '../application/subscription.service';

@ApiTags('subscription')
@ApiBearerAuth()
@Controller('subscription')
export class SubscriptionController {
  constructor(private readonly subscription: SubscriptionService) {}

  @Get()
  @ApiOperation({ summary: 'Current subscription status' })
  async status(@CurrentUser('userId') userId: string) {
    return this.subscription.getStatus(userId);
  }

  @Post('checkout')
  @ApiOperation({ summary: 'Start a Stripe Checkout session for Premium' })
  async checkout(
    @CurrentUser('userId') userId: string,
    @CurrentUser('email') email: string,
  ) {
    return this.subscription.createCheckoutSession(userId, email);
  }

  @Post('iap')
  @ApiOperation({
    summary: 'Redeem an Apple/Google in-app-purchase receipt for Premium',
  })
  async redeem(
    @CurrentUser('userId') userId: string,
    @Body() dto: RedeemReceiptDto,
  ) {
    return this.subscription.redeemReceipt(userId, dto.provider, dto.receipt);
  }

  @Public()
  @Post('webhook')
  @ApiOperation({
    summary: 'Stripe billing webhook (public, signature-verified)',
  })
  async webhook(
    @Req() req: Request,
    @Headers('stripe-signature') signature?: string,
  ) {
    // Prefer the raw body (needed for signature verification) when the platform
    // exposes it; fall back to the parsed body otherwise.
    const raw =
      (req as Request & { rawBody?: Buffer }).rawBody ??
      JSON.stringify(req.body ?? {});
    return this.subscription.handleWebhook(raw, signature);
  }
}
