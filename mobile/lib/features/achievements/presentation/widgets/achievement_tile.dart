import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/achievement.dart';

/// A single achievement in the gallery grid. Locked ones are desaturated with a
/// progress ring; unlocked ones glow in their rarity color.
class AchievementTile extends StatelessWidget {
  const AchievementTile({super.key, required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final a = achievement;
    final unlocked = a.isUnlocked;
    final color = a.rarityColor;
    final showSecret = a.isSecret && !unlocked;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: unlocked ? color.withValues(alpha: 0.6) : scheme.outline),
        boxShadow: unlocked
            ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 52,
                width: 52,
                child: CircularProgressIndicator(
                  value: unlocked ? 1 : a.progress,
                  strokeWidth: 3,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Icon(
                showSecret ? Icons.help_outline_rounded : Icons.emoji_events_rounded,
                color: unlocked ? color : scheme.outline,
                size: 24,
              ),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            showSecret ? 'Secret' : a.name,
            style: text.labelMedium?.copyWith(color: unlocked ? scheme.onSurface : null),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            unlocked ? a.rarity : '${(a.progress * 100).round()}%',
            style: text.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
