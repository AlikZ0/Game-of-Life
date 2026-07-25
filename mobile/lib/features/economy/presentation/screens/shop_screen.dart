import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../../character/presentation/providers/character_providers.dart';
import '../providers/economy_providers.dart';
import '../widgets/shop_reward_card.dart';

/// Shop of user-defined real-life rewards, purchasable with earned gold.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  Future<void> _redeem(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(redeemRewardProvider)(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reward redeemed! Enjoy it — you earned it.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(shopRewardsProvider);
    final gold = ref.watch(myCharacterProvider).valueOrNull?.gold ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.paid_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 4),
                Text(Formatters.count(gold),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.gold)),
              ],
            ),
          ),
        ],
      ),
      body: rewards.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(shopRewardsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyView(
              title: 'Your shop is empty',
              subtitle: 'Add real-life rewards (a movie night, a treat) to spend gold on.',
              icon: Icons.storefront_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: list.length,
            separatorBuilder: (_, __) => AppSpacing.vMd,
            itemBuilder: (context, i) {
              final r = list[i];
              return ShopRewardCard(
                reward: r,
                canAfford: gold >= r.goldCost,
                onRedeem: () => _redeem(context, ref, r.id),
              );
            },
          );
        },
      ),
    );
  }
}
