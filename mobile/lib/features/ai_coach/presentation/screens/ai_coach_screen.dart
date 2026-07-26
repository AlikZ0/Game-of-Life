import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../domain/entities/coach_analysis.dart';
import '../providers/coach_providers.dart';

/// AI Coach: a personalized analysis of recent activity with strengths, weak
/// areas, and recommended quests.
class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(coachAnalysisProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(coachAnalysisProvider),
        child: analysis.when(
          loading: () => const LoadingView(message: 'Analyzing your last few weeks…'),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(coachAnalysisProvider)),
          data: (a) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _CoachHeader(analysis: a),
              AppSpacing.vXl,
              if (a.strengths.isNotEmpty) ...[
                _ChipSection(
                  title: 'Strengths',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                  labels: a.strengths,
                ),
                AppSpacing.vLg,
              ],
              if (a.weakAreas.isNotEmpty) ...[
                _ChipSection(
                  title: 'Needs attention',
                  icon: Icons.trending_down_rounded,
                  color: AppColors.warning,
                  labels: a.weakAreas,
                ),
                AppSpacing.vXl,
              ],
              if (a.suggestedQuests.isNotEmpty) ...[
                Text('Suggested quests', style: Theme.of(context).textTheme.titleMedium),
                AppSpacing.vLg,
                for (final q in a.suggestedQuests) ...[
                  _SuggestedQuestCard(quest: q),
                  AppSpacing.vMd,
                ],
              ] else
                const EmptyView(
                  title: 'No suggestions right now',
                  subtitle: 'Keep questing — your coach will have ideas soon.',
                  icon: Icons.psychology_rounded,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachHeader extends StatelessWidget {
  const _CoachHeader({required this.analysis});
  final CoachAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: AppRadius.rXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
              AppSpacing.hMd,
              Expanded(
                child: Text(
                  analysis.summary.isEmpty
                      ? 'Your coach analyzed your recent activity.'
                      : analysis.summary,
                  style: text.titleSmall?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          if (analysis.predictedLevelIn30d != null) ...[
            AppSpacing.vLg,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: AppRadius.rMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timeline_rounded, color: Colors.white, size: 18),
                  AppSpacing.hSm,
                  Text(
                    'Projected level in 30 days: ${Formatters.count(analysis.predictedLevelIn30d!)}',
                    style: text.labelMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.labels,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            AppSpacing.hSm,
            Text(title, style: text.titleSmall),
          ],
        ),
        AppSpacing.vMd,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final label in labels)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.rPill,
                ),
                child: Text(
                  Formatters.enumLabel(label),
                  style: text.labelMedium?.copyWith(color: color),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SuggestedQuestCard extends StatelessWidget {
  const _SuggestedQuestCard({required this.quest});
  final SuggestedQuest quest;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final diffColor = AppColors.difficulty[quest.difficulty] ?? AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(quest.title, style: text.titleSmall)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.16),
                  borderRadius: AppRadius.rSm,
                ),
                child: Text(
                  Formatters.enumLabel(quest.difficulty),
                  style: text.labelSmall?.copyWith(color: diffColor),
                ),
              ),
            ],
          ),
          AppSpacing.gapXs,
          Row(
            children: [
              Icon(Icons.repeat_rounded, size: 14, color: scheme.outline),
              const SizedBox(width: 4),
              Text(Formatters.enumLabel(quest.cadence), style: text.labelSmall),
              if (quest.skillKey.isNotEmpty) ...[
                AppSpacing.hSm,
                Icon(Icons.auto_graph_rounded, size: 14, color: scheme.outline),
                const SizedBox(width: 4),
                Text(Formatters.enumLabel(quest.skillKey), style: text.labelSmall),
              ],
            ],
          ),
          if (quest.rationale.isNotEmpty) ...[
            AppSpacing.gapSm,
            Text(quest.rationale, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}
