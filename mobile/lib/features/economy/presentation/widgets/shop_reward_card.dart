import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/shop_reward.dart';

/// A purchasable real-life reward card with a gold-cost buy button.
class ShopRewardCard extends StatelessWidget {
  const ShopRewardCard({
    super.key,
    required this.reward,
    required this.canAfford,
    required this.onRedeem,
  });

  final ShopReward reward;
  final bool canAfford;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final enabled = canAfford && !reward.isSoldOut;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: AppRadius.rMd,
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white),
          ),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (reward.description != null)
                  Text(reward.description!, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          AppSpacing.hSm,
          FilledButton(
            onPressed: enabled ? onRedeem : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.paid_rounded, size: 16),
                const SizedBox(width: 4),
                Text(reward.isSoldOut ? 'Sold out' : Formatters.count(reward.goldCost)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
