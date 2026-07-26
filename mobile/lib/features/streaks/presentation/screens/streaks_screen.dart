import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../../../core/widgets/xp_bar.dart';
import '../../domain/entities/streak.dart';
import '../providers/streak_providers.dart';

/// Streak milestones view: big current count, freeze inventory, and a timeline
/// of milestone rewards.
class StreaksScreen extends ConsumerWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final streak = ref.watch(streakProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.streakTitle)),
      body: streak.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(streakProvider)),
        data: (s) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _Header(streak: s),
            AppSpacing.vXxl,
            Text(l10n.milestones, style: Theme.of(context).textTheme.titleMedium),
            AppSpacing.vLg,
            for (final m in Streak.milestones)
              _MilestoneTile(days: m, reached: s.current >= m, current: s.current),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.streak});
  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.warning, AppColors.tertiary]),
        borderRadius: AppRadius.rXl,
      ),
      child: Column(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 64),
          Text('${streak.current}', style: text.displayLarge?.copyWith(color: Colors.white)),
          Text(AppLocalizations.of(context).dayStreakLabel, style: text.titleMedium?.copyWith(color: Colors.white70)),
          AppSpacing.vLg,
          XpBar(
            value: streak.milestoneProgress,
            gradient: const LinearGradient(colors: [Colors.white, Colors.white70]),
            background: Colors.white24,
          ),
          AppSpacing.gapXs,
          Text(
            '${streak.nextMilestone - streak.current} days to your next reward',
            style: text.labelSmall?.copyWith(color: Colors.white70),
          ),
          AppSpacing.vLg,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'Longest', value: '${streak.longest}'),
              _Stat(label: 'Freezes', value: '${streak.freezeCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: text.headlineMedium?.copyWith(color: Colors.white)),
        Text(label, style: text.labelSmall?.copyWith(color: Colors.white70)),
      ],
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.days, required this.reached, required this.current});
  final int days;
  final bool reached;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: reached ? AppColors.warning : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              reached ? Icons.check_rounded : Icons.lock_outline_rounded,
              color: reached ? Colors.white : scheme.outline,
              size: 20,
            ),
          ),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).streakDays(days), style: Theme.of(context).textTheme.titleSmall),
                Text(AppLocalizations.of(context).milestoneReward, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (!reached)
            Text('${days - current}d', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
