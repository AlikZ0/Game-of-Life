import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_views.dart';
import '../../../../core/widgets/xp_bar.dart';
import '../../domain/entities/guild.dart';
import '../providers/social_providers.dart';
import '../widgets/leaderboard_tile.dart';

/// Guild screen with three tabs: Missions, Leaderboard, Chat.
class GuildScreen extends ConsumerWidget {
  const GuildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final guild = ref.watch(myGuildProvider);

    return guild.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.guildTitle)),
        body: ErrorView(message: e.toString(), onRetry: () => ref.invalidate(myGuildProvider)),
      ),
      data: (g) {
        if (g == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.guildTitle)),
            body: const EmptyView(
              title: "You're not in a guild yet",
              subtitle: 'Join or create a guild to tackle shared missions and climb leaderboards.',
              icon: Icons.groups_rounded,
            ),
          );
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text('${g.name} [${g.tag}]'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Missions'),
                  Tab(text: 'Leaderboard'),
                  Tab(text: 'Chat'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _MissionsTab(guild: g),
                _LeaderboardTab(guild: g),
                const _ChatTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MissionsTab extends StatelessWidget {
  const _MissionsTab({required this.guild});
  final Guild guild;

  @override
  Widget build(BuildContext context) {
    if (guild.missions.isEmpty) {
      return const EmptyView(title: 'No active missions', icon: Icons.flag_rounded);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: guild.missions.length,
      separatorBuilder: (_, __) => AppSpacing.vLg,
      itemBuilder: (context, i) {
        final m = guild.missions[i];
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
            children: [
              Row(
                children: [
                  Expanded(child: Text(m.title, style: text.titleSmall)),
                  Text('+${Formatters.count(m.rewardGold)}g',
                      style: text.labelMedium?.copyWith(color: AppColors.gold)),
                ],
              ),
              AppSpacing.vMd,
              XpBar(value: m.progress),
              AppSpacing.gapXs,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${Formatters.count(m.currentValue)} / ${Formatters.count(m.targetValue)} ${Formatters.enumLabel(m.metric)}',
                      style: text.labelSmall),
                  Text(Formatters.countdown(m.expiresAt.difference(DateTime.now())),
                      style: text.labelSmall),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({required this.guild});
  final Guild guild;

  @override
  Widget build(BuildContext context) {
    final members = [...guild.members]..sort((a, b) => b.weeklyXp.compareTo(a.weeklyXp));
    if (members.isEmpty) {
      return const EmptyView(title: 'No members yet', icon: Icons.people_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: members.length,
      itemBuilder: (context, i) => LeaderboardTile(rank: i + 1, member: members[i]),
    );
  }
}

/// Chat tab — structural stub. A production build wires this to Socket.IO
/// (`WS_BASE_URL`) for realtime guild messages.
class _ChatTab extends StatelessWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: EmptyView(
            title: 'Guild chat',
            subtitle: 'Realtime messages appear here (Socket.IO).',
            icon: Icons.chat_bubble_outline_rounded,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: 'Message your guild…'),
                ),
              ),
              AppSpacing.hSm,
              IconButton.filled(
                onPressed: () {},
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
