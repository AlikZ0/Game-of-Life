import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/xp_bar.dart';
import '../providers/stats_providers.dart';
import '../widgets/xp_line_chart.dart';

/// Statistics dashboard: XP trend line chart, completion rate, and headline
/// metric tiles.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: stats.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(statsSummaryProvider)),
        data: (s) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('XP over time', style: Theme.of(context).textTheme.titleMedium),
            AppSpacing.vLg,
            GlassCard(blur: false, child: XpLineChart(points: s.xpSeries)),
            AppSpacing.vXl,
            GlassCard(
              blur: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Completion rate', style: Theme.of(context).textTheme.titleSmall),
                      Text(Formatters.percent(s.completionRate),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.success)),
                    ],
                  ),
                  AppSpacing.vMd,
                  XpBar(
                    value: s.completionRate,
                    gradient: const LinearGradient(colors: [AppColors.success, AppColors.secondary]),
                  ),
                ],
              ),
            ),
            AppSpacing.vXl,
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.6,
              children: [
                _MetricTile(icon: Icons.check_circle_rounded, label: 'Quests done', value: Formatters.count(s.questsCompleted), color: AppColors.accent),
                _MetricTile(icon: Icons.bolt_rounded, label: 'Total XP', value: Formatters.compact(s.totalXp), color: AppColors.xp),
                _MetricTile(icon: Icons.paid_rounded, label: 'Total gold', value: Formatters.compact(s.totalGold), color: AppColors.gold),
                _MetricTile(icon: Icons.calendar_today_rounded, label: 'Active days', value: Formatters.count(s.activeDays), color: AppColors.secondary),
              ],
            ),
          ],
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
