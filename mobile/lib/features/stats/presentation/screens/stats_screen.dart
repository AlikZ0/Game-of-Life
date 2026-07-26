import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/xp_bar.dart';
import '../../domain/entities/life_balance.dart';
import '../../domain/entities/stats_dashboard.dart';
import '../providers/stats_providers.dart';
import '../widgets/xp_line_chart.dart';

/// Statistics dashboard: headline metric tiles, an XP trend line chart, and a
/// life-balance breakdown across skill areas.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(statsDashboardProvider);
    final xpSeries = ref.watch(statsXpSeriesProvider);
    final lifeBalance = ref.watch(statsLifeBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsDashboardProvider);
          ref.invalidate(statsXpSeriesProvider);
          ref.invalidate(statsLifeBalanceProvider);
        },
        child: dashboard.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(statsDashboardProvider),
          ),
          data: (s) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.6,
                children: [
                  _MetricTile(icon: Icons.military_tech_rounded, label: 'Level', value: Formatters.count(s.level), color: AppColors.accent),
                  _MetricTile(icon: Icons.bolt_rounded, label: 'Total XP', value: Formatters.compact(s.totalXp), color: AppColors.xp),
                  _MetricTile(icon: Icons.paid_rounded, label: 'Gold', value: Formatters.compact(s.gold), color: AppColors.gold),
                  _MetricTile(icon: Icons.check_circle_rounded, label: 'Done (30d)', value: Formatters.count(s.questsCompleted30d), color: AppColors.success),
                  _MetricTile(icon: Icons.flag_rounded, label: 'Active quests', value: Formatters.count(s.activeQuests), color: AppColors.info),
                  _MetricTile(icon: Icons.local_fire_department_rounded, label: 'Streak', value: '${s.currentStreak} / ${s.longestStreak}', color: AppColors.warning),
                ],
              ),
              AppSpacing.vXl,
              Text('XP over time', style: Theme.of(context).textTheme.titleMedium),
              AppSpacing.vLg,
              GlassCard(
                blur: false,
                child: xpSeries.when(
                  loading: () => const SizedBox(height: 220, child: LoadingView()),
                  error: (e, _) => SizedBox(
                    height: 220,
                    child: ErrorView(message: e.toString(), onRetry: () => ref.invalidate(statsXpSeriesProvider)),
                  ),
                  data: (points) => XpLineChart(points: points),
                ),
              ),
              AppSpacing.vXl,
              Text('Life balance', style: Theme.of(context).textTheme.titleMedium),
              AppSpacing.vLg,
              lifeBalance.when(
                loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: LoadingView()),
                error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(statsLifeBalanceProvider)),
                data: (slices) {
                  if (slices.isEmpty) {
                    return const EmptyView(
                      title: 'No balance data yet',
                      subtitle: 'Complete skill-linked quests to see how your effort is distributed.',
                      icon: Icons.balance_rounded,
                    );
                  }
                  return GlassCard(
                    blur: false,
                    child: Column(
                      children: [
                        for (final slice in slices) ...[
                          _BalanceRow(slice: slice),
                          if (slice != slices.last) AppSpacing.vLg,
                        ],
                      ],
                    ),
                  );
                },
              ),
              if (s.skillBalance.isNotEmpty) ...[
                AppSpacing.vXl,
                Text('Skill XP', style: Theme.of(context).textTheme.titleMedium),
                AppSpacing.vLg,
                for (final sb in s.skillBalance) ...[
                  _SkillBalanceRow(balance: sb),
                  AppSpacing.vMd,
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Text(value, style: text.headlineMedium),
          Text(label, style: text.labelSmall),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.slice});
  final LifeBalanceSlice slice;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(slice.name, style: text.titleSmall)),
            if (slice.neglected)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text('Neglected', style: text.labelSmall?.copyWith(color: AppColors.warning)),
              ),
            Text(Formatters.percent(slice.share), style: text.labelMedium),
          ],
        ),
        AppSpacing.gapSm,
        XpBar(
          value: slice.share,
          gradient: LinearGradient(
            colors: slice.neglected
                ? const [AppColors.warning, AppColors.tertiary]
                : const [AppColors.accent, AppColors.secondary],
          ),
        ),
      ],
    );
  }
}

class _SkillBalanceRow extends StatelessWidget {
  const _SkillBalanceRow({required this.balance});
  final SkillBalance balance;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Expanded(child: Text(balance.name, style: text.titleSmall)),
          Text('Lvl ${balance.level}', style: text.labelMedium?.copyWith(color: AppColors.accent)),
          AppSpacing.hMd,
          Text('${Formatters.compact(balance.totalXp)} XP', style: text.labelSmall),
        ],
      ),
    );
  }
}
