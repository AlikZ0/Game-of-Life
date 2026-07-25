import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../../../core/widgets/glass_card.dart';
import '../providers/skills_providers.dart';
import '../widgets/skill_heatmap.dart';
import '../widgets/skill_tile.dart';

/// Skills tab: an activity heatmap card followed by a list of skills with
/// progress bars.
class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(skillsProvider);
    final heatmap = ref.watch(skillHeatmapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Skills')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(skillsProvider);
          ref.invalidate(skillHeatmapProvider);
        },
        child: skills.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(skillsProvider)),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyView(
                title: 'No skills yet',
                subtitle: 'Complete quests linked to skills to start leveling them.',
                icon: Icons.auto_graph_rounded,
              );
            }
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                GlassCard(
                  blur: false,
                  child: heatmap.maybeWhen(
                    data: (cells) => SkillHeatmap(cells: cells),
                    orElse: () => const SizedBox(height: 120, child: LoadingView()),
                  ),
                ),
                AppSpacing.vXl,
                Text('Your skills', style: Theme.of(context).textTheme.titleMedium),
                AppSpacing.vLg,
                for (final s in list) ...[
                  SkillTile(skill: s),
                  AppSpacing.vMd,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
