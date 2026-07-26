import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../../../core/widgets/stat_pill.dart';
import '../../../character/presentation/providers/character_providers.dart';
import '../../../quests/domain/entities/quest.dart';
import '../../../quests/presentation/providers/quests_controller.dart';
import '../../../quests/presentation/widgets/quest_card.dart';
import '../../../quests/presentation/widgets/reward_burst_sheet.dart';
import '../../domain/entities/boss.dart';
import '../providers/bosses_providers.dart';
import '../widgets/hp_bar.dart';

/// Flagship boss detail: a dramatic HP header, reward summary, and the list of
/// linked quests. Completing a linked quest deals damage and refreshes the HP.
class BossDetailScreen extends ConsumerWidget {
  const BossDetailScreen({super.key, required this.bossId});
  final String bossId;

  Future<void> _completeLinked(BuildContext context, WidgetRef ref, Quest quest) async {
    if (quest.completedForPeriod) return;
    final result = await ref.read(completeQuestProvider)(quest.id);
    await result.fold(
      onSuccess: (reward) async {
        ref.invalidate(bossDetailProvider(bossId));
        ref.invalidate(bossQuestsProvider(bossId));
        ref.invalidate(myCharacterProvider);
        if (context.mounted) await RewardBurstSheet.show(context, reward);
      },
      onFailure: (e) async {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boss = ref.watch(bossDetailProvider(bossId));
    final quests = ref.watch(bossQuestsProvider(bossId));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: boss.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(bossDetailProvider(bossId))),
        data: (b) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _BossHeader(boss: b),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList.list(
                children: [
                  if (b.description != null) ...[
                    Text(b.description!, style: Theme.of(context).textTheme.bodyMedium),
                    AppSpacing.vLg,
                  ],
                  Row(
                    children: [
                      StatPill(icon: Icons.bolt_rounded, value: Formatters.count(b.rewardXp), color: AppColors.xp, label: 'XP'),
                      AppSpacing.hSm,
                      StatPill(icon: Icons.paid_rounded, value: Formatters.count(b.rewardGold), color: AppColors.gold, label: 'gold'),
                    ],
                  ),
                  AppSpacing.vXl,
                  Text(l10n.attackingQuests, style: Theme.of(context).textTheme.titleMedium),
                  AppSpacing.vLg,
                  quests.when(
                    loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: LoadingView()),
                    error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(bossQuestsProvider(bossId))),
                    data: (list) {
                      if (list.isEmpty) {
                        return const EmptyView(
                          title: 'No quests attacking this boss',
                          subtitle: 'Link daily quests to deal damage each time you complete them.',
                          icon: Icons.link_rounded,
                        );
                      }
                      return Column(
                        children: [
                          for (final q in list) ...[
                            QuestCard(
                              quest: q,
                              onToggleComplete: () => _completeLinked(context, ref, q),
                            ),
                            AppSpacing.vMd,
                          ],
                        ],
                      );
                    },
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

class _BossHeader extends StatelessWidget {
  const _BossHeader({required this.boss});
  final Boss boss;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: boss.isDefeated
              ? [AppColors.success, AppColors.secondary]
              : [AppColors.accentDeep, AppColors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 48, AppSpacing.xxl, AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                boss.isDefeated ? Icons.emoji_events_rounded : Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 52,
              ),
              const Spacer(),
              Text(boss.name, style: text.displayMedium?.copyWith(color: Colors.white)),
              AppSpacing.vMd,
              HpBar(fraction: boss.hpFraction, height: 20),
              AppSpacing.gapSm,
              Text(
                boss.isDefeated
                    ? 'Defeated! 🏆'
                    : '${Formatters.count(boss.currentHp)} / ${Formatters.count(boss.maxHp)} HP  •  ${Formatters.percent(boss.progress)} down',
                style: text.labelMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
