import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/guild.dart';

/// A ranked row for the guild leaderboard: rank medal, name, level, weekly XP.
class LeaderboardTile extends StatelessWidget {
  const LeaderboardTile({super.key, required this.rank, required this.member});

  final int rank;
  final GuildMember member;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final medal = switch (rank) {
      1 => AppColors.gold,
      2 => AppColors.rarity['SILVER'],
      3 => AppColors.rarity['BRONZE'],
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: medal != null
                ? Icon(Icons.workspace_premium_rounded, color: medal)
                : Text('$rank', style: text.titleSmall, textAlign: TextAlign.center),
          ),
          AppSpacing.hMd,
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
          ),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${member.role} • Lvl ${member.level}', style: text.labelSmall),
              ],
            ),
          ),
          Text(Formatters.xp(member.weeklyXp),
              style: text.labelMedium?.copyWith(color: AppColors.accent)),
        ],
      ),
    );
  }
}
