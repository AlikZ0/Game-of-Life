import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../domain/entities/inventory_item.dart';
import '../providers/economy_providers.dart';

/// Inventory of owned cosmetics, titles, coupons, and consumables.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: inventory.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(inventoryProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyView(
              title: 'Nothing here yet',
              subtitle: 'Earn cosmetics and consumables from quests, bosses, and the battle pass.',
              icon: Icons.backpack_rounded,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.4,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) => _ItemCard(item: list[i]),
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: item.equipped ? AppColors.accent : scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(item.itemType), color: AppColors.accent),
          const Spacer(),
          Text(item.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(Formatters.enumLabel(item.itemType), style: text.labelSmall),
          if (item.quantity > 1)
            Text('×${item.quantity}', style: text.labelSmall?.copyWith(color: AppColors.accent)),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    if (type.startsWith('COSMETIC')) return Icons.palette_rounded;
    if (type == 'TITLE') return Icons.military_tech_rounded;
    if (type == 'REWARD_COUPON') return Icons.confirmation_number_rounded;
    return Icons.science_rounded;
  }
}
