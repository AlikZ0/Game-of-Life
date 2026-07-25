import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../../character/presentation/providers/character_providers.dart';
import '../../../character/presentation/widgets/character_card.dart';
import '../../../streaks/presentation/widgets/streak_flame.dart';
import '../../domain/entities/quest.dart';
import '../../domain/entities/quest_enums.dart';
import '../providers/quests_controller.dart';
import '../widgets/quest_card.dart';
import '../widgets/quest_edit_sheet.dart';
import '../widgets/reward_burst_sheet.dart';

/// Flagship home dashboard: character hero header, a streak flame, quick
/// shortcuts, a cadence filter, and the list of daily quests with one-tap
/// completion that fires the reward burst.
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  Future<void> _complete(BuildContext context, WidgetRef ref, Quest quest) async {
    if (quest.completedForPeriod) return;
    try {
      final reward = await ref.read(questsControllerProvider.notifier).complete(quest.id);
      if (context.mounted) await RewardBurstSheet.show(context, reward);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(myCharacterProvider);
    final quests = ref.watch(questsControllerProvider);
    final filter = ref.watch(questCadenceFilterProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuestEditSheet.show(context),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New quest', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.invalidate(myCharacterProvider);
          await ref.read(questsControllerProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              titleSpacing: AppSpacing.lg,
              title: const _Greeting(),
              actions: [
                const StreakFlame(),
                IconButton(
                  icon: const Icon(Icons.insights_rounded),
                  onPressed: () => context.pushNamed(AppRoute.stats.name),
                ),
                AppSpacing.hSm,
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 120),
              sliver: SliverList.list(
                children: [
                  character.when(
                    data: (c) => CharacterCard(
                      character: c,
                      onTap: () => context.pushNamed(AppRoute.profile.name),
                    ),
                    loading: () => const SizedBox(height: 220, child: LoadingView()),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(myCharacterProvider),
                    ),
                  ),
                  AppSpacing.vXl,
                  const _QuickActions(),
                  AppSpacing.vXl,
                  _CadenceFilter(
                    selected: filter,
                    onSelected: (value) =>
                        ref.read(questCadenceFilterProvider.notifier).state = value,
                  ),
                  AppSpacing.vLg,
                  quests.when(
                    data: (list) => _QuestList(
                      quests: list,
                      onComplete: (q) => _complete(context, ref, q),
                      onEdit: (q) => QuestEditSheet.show(context, existing: q),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.huge),
                      child: LoadingView(),
                    ),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.read(questsControllerProvider.notifier).refresh(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(greeting, style: Theme.of(context).textTheme.bodySmall),
        Text('Your quests', style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, AppRoute, Color)>[
      (Icons.local_fire_department_rounded, 'Bosses', AppRoute.bosses, AppColors.tertiary),
      (Icons.storefront_rounded, 'Shop', AppRoute.shop, AppColors.gold),
      (Icons.psychology_rounded, 'AI Coach', AppRoute.aiCoach, AppColors.secondary),
      (Icons.workspace_premium_rounded, 'Pass', AppRoute.battlePass, AppColors.accent),
    ];
    return Row(
      children: [
        for (final a in actions)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _QuickAction(icon: a.$1, label: a.$2, route: a.$3, color: a.$4),
            ),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String label;
  final AppRoute route;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.pushNamed(route.name),
      child: Column(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: AppRadius.rMd,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color),
          ),
          AppSpacing.gapXs,
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurface)),
        ],
      ),
    );
  }
}

class _CadenceFilter extends StatelessWidget {
  const _CadenceFilter({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final c in QuestCadence.values) ...[
            AppSpacing.hSm,
            ChoiceChip(
              label: Text(c.label),
              selected: selected == c.apiValue,
              onSelected: (_) => onSelected(c.apiValue),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestList extends StatelessWidget {
  const _QuestList({
    required this.quests,
    required this.onComplete,
    required this.onEdit,
  });

  final List<Quest> quests;
  final void Function(Quest) onComplete;
  final void Function(Quest) onEdit;

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return const EmptyView(
        title: 'No quests yet',
        subtitle: 'Tap “New quest” to turn a habit into an adventure.',
        icon: Icons.explore_rounded,
      );
    }
    final active = quests.where((q) => !q.completedForPeriod).toList();
    final done = quests.where((q) => q.completedForPeriod).toList();

    return Column(
      children: [
        for (final q in active) ...[
          QuestCard(quest: q, onToggleComplete: () => onComplete(q), onTap: () => onEdit(q)),
          AppSpacing.vMd,
        ],
        if (done.isNotEmpty) ...[
          AppSpacing.vSm,
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Completed today (${done.length})',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          AppSpacing.vMd,
          for (final q in done) ...[
            QuestCard(quest: q, onToggleComplete: () {}, onTap: () => onEdit(q)),
            AppSpacing.vMd,
          ],
        ],
      ],
    );
  }
}
