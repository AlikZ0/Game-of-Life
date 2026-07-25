import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../domain/entities/pvp_challenge.dart';
import '../providers/social_providers.dart';

/// PvP arena: list of active duels with live score comparison.
class PvpScreen extends ConsumerWidget {
  const PvpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(pvpChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PvP Arena')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.tertiary,
        onPressed: () {},
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New challenge', style: TextStyle(color: Colors.white)),
      ),
      body: challenges.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(pvpChallengesProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyView(
              title: 'No active duels',
              subtitle: 'Challenge a friend to an XP or study-minute showdown.',
              icon: Icons.sports_kabaddi_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: list.length,
            separatorBuilder: (_, __) => AppSpacing.vLg,
            itemBuilder: (context, i) => _ChallengeCard(challenge: list[i]),
          );
        },
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});
  final PvpChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = challenge;
    final total = (c.myScore + c.theirScore).clamp(1, 1 << 31);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('vs ${c.opponentName}', style: text.titleSmall),
              Chip(label: Text(Formatters.enumLabel(c.metric))),
            ],
          ),
          AppSpacing.vMd,
          Row(
            children: [
              _Score(label: 'You', value: c.myScore, color: AppColors.accent, leading: true),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.rPill,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (c.myScore / total * 100).round().clamp(1, 100),
                        child: Container(height: 10, color: AppColors.accent),
                      ),
                      Expanded(
                        flex: (c.theirScore / total * 100).round().clamp(1, 100),
                        child: Container(height: 10, color: AppColors.tertiary),
                      ),
                    ],
                  ),
                ),
              ),
              _Score(label: c.opponentName, value: c.theirScore, color: AppColors.tertiary, leading: false),
            ],
          ),
          AppSpacing.vSm,
          Text(
            c.isActive
                ? 'Ends in ${Formatters.countdown(c.endAt.difference(DateTime.now()))}'
                : Formatters.enumLabel(c.status),
            style: text.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value, required this.color, required this.leading});
  final String label;
  final int value;
  final Color color;
  final bool leading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final child = Column(
      crossAxisAlignment: leading ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text('$value', style: text.titleMedium?.copyWith(color: color)),
        Text(label, style: text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
    return SizedBox(width: 64, child: child);
  }
}
