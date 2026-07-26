import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../providers/achievements_providers.dart';
import '../widgets/achievement_tile.dart';

/// Achievement gallery: a rarity-colored grid of unlocked + in-progress badges.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: achievements.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(achievementsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(title: l10n.achievementsEmpty, icon: Icons.emoji_events_rounded);
          }
          final unlocked = list.where((a) => a.isUnlocked).length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.achievementsUnlocked(unlocked, list.length),
                      style: Theme.of(context).textTheme.titleSmall),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) => AchievementTile(achievement: list[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
