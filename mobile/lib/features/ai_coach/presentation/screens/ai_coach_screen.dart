import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../domain/entities/coach_suggestion.dart';
import '../providers/coach_providers.dart';

/// AI Coach: a personalized feed of suggestions based on recent activity.
class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(coachSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: suggestions.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(coachSuggestionsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyView(
              title: 'All caught up',
              subtitle: 'Your coach has no new suggestions. Keep questing!',
              icon: Icons.psychology_rounded,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const _CoachHeader(),
              AppSpacing.vXl,
              for (final s in list) ...[
                _SuggestionCard(suggestion: s),
                AppSpacing.vMd,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CoachHeader extends StatelessWidget {
  const _CoachHeader();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: AppRadius.rXl),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
          AppSpacing.hMd,
          Expanded(
            child: Text(
              'Your coach analyzed the last 7 days and has a few ideas.',
              style: text.titleSmall?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});
  final CoachSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (suggestion.type) {
      'warning' => (Icons.warning_amber_rounded, AppColors.warning),
      'motivation' => (Icons.emoji_emotions_rounded, AppColors.tertiary),
      'insight' => (Icons.insights_rounded, AppColors.secondary),
      _ => (Icons.lightbulb_outline_rounded, AppColors.accent),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: AppRadius.rMd),
            child: Icon(icon, color: color, size: 22),
          ),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.title, style: text.titleSmall),
                AppSpacing.gapXs,
                Text(suggestion.body, style: text.bodySmall),
                if (suggestion.actionLabel != null) ...[
                  AppSpacing.gapSm,
                  TextButton(onPressed: () {}, child: Text(suggestion.actionLabel!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
