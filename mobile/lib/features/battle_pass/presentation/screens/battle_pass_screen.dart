import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../domain/entities/battle_pass.dart';
import '../providers/battle_pass_providers.dart';

/// Battle pass track: a horizontally scrolling tier ladder with free + premium
/// reward rows and a premium upsell.
class BattlePassScreen extends ConsumerWidget {
  const BattlePassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pass = ref.watch(battlePassProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Battle Pass')),
      body: pass.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(battlePassProvider)),
        data: (p) => Column(
          children: [
            _Header(pass: p),
            const Divider(height: 1),
            Expanded(child: _TierTrack(pass: p)),
            if (!p.isPremium) _PremiumUpsell(onTap: () => context.pushNamed(AppRoute.paywall.name)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pass});
  final BattlePass pass;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
            child: Center(child: Text('${pass.currentTier}', style: text.titleMedium?.copyWith(color: Colors.white))),
          ),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pass.seasonName, style: text.titleMedium),
                Text('Ends in ${Formatters.countdown(pass.endAt.difference(DateTime.now()))}',
                    style: text.labelSmall),
              ],
            ),
          ),
          if (pass.isPremium)
            const Chip(
              backgroundColor: AppColors.gold,
              label: Text('PREMIUM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _TierTrack extends StatelessWidget {
  const _TierTrack({required this.pass});
  final BattlePass pass;

  @override
  Widget build(BuildContext context) {
    if (pass.tiers.isEmpty) {
      return const EmptyView(title: 'No active season', icon: Icons.workspace_premium_rounded);
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: pass.tiers.length,
      itemBuilder: (context, i) {
        final t = pass.tiers[i];
        final reached = pass.currentTier >= t.tier;
        return _TierColumn(tier: t, reached: reached, isPremium: pass.isPremium, claimed: pass.isClaimed(t.tier));
      },
    );
  }
}

class _TierColumn extends StatelessWidget {
  const _TierColumn({
    required this.tier,
    required this.reached,
    required this.isPremium,
    required this.claimed,
  });

  final BattlePassTier tier;
  final bool reached;
  final bool isPremium;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          _RewardChip(label: tier.freeReward ?? '—', unlocked: reached, claimed: claimed, accent: AppColors.secondary),
          AppSpacing.vMd,
          CircleAvatar(
            radius: 16,
            backgroundColor: reached ? AppColors.accent : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text('${tier.tier}',
                style: TextStyle(color: reached ? Colors.white : null, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          AppSpacing.vMd,
          _RewardChip(
            label: tier.premiumReward ?? '—',
            unlocked: reached && isPremium,
            claimed: claimed,
            accent: AppColors.gold,
            locked: !isPremium,
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.label,
    required this.unlocked,
    required this.claimed,
    required this.accent,
    this.locked = false,
  });

  final String label;
  final bool unlocked;
  final bool claimed;
  final Color accent;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 72,
      width: 72,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: unlocked ? accent.withValues(alpha: 0.18) : scheme.surface,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: unlocked ? accent : scheme.outline),
      ),
      child: locked
          ? Icon(Icons.lock_rounded, color: scheme.outline, size: 20)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(claimed ? Icons.check_rounded : Icons.card_giftcard_rounded,
                    color: unlocked ? accent : scheme.outline, size: 20),
                const SizedBox(height: 2),
                Text(label,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
    );
  }
}

class _PremiumUpsell extends StatelessWidget {
  const _PremiumUpsell({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: AppRadius.rLg),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.black),
                AppSpacing.hMd,
                Expanded(
                  child: Text('Unlock the Premium track',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.black)),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
