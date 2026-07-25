import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/level_badge.dart';
import '../../../../core/widgets/stat_pill.dart';
import '../../../../core/widgets/xp_bar.dart';
import '../../domain/entities/character.dart';

/// The hero "character header" used atop the dashboard + profile. Shows
/// avatar, name, class, level, an XP bar, and HP/Energy/Gold pills.
class CharacterCard extends StatelessWidget {
  const CharacterCard({super.key, required this.character, this.onTap});

  final Character character;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = character;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: c.characterClass.gradient,
          borderRadius: AppRadius.rXl,
          boxShadow: [
            BoxShadow(
              color: c.characterClass.color.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(icon: c.characterClass.icon),
                AppSpacing.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: text.headlineMedium?.copyWith(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        c.activeTitle ?? '${c.characterClass.label} • Lvl ${c.level}',
                        style: text.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                LevelBadge(level: c.level, gradient: AppColors.goldGradient),
              ],
            ),
            AppSpacing.vLg,
            XpBar(
              value: c.levelProgress,
              gradient: const LinearGradient(colors: [Colors.white, Colors.white70]),
              background: Colors.white24,
            ),
            AppSpacing.gapXs,
            Text(
              '${Formatters.count(c.xp)} / ${Formatters.count(c.xpForNextLevel)} XP to next level',
              style: text.labelSmall?.copyWith(color: Colors.white70),
            ),
            AppSpacing.vLg,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                StatPill(icon: Icons.favorite_rounded, value: '${c.hp}/${c.maxHp}', color: Colors.white),
                StatPill(icon: Icons.bolt_rounded, value: '${c.energy}/${c.maxEnergy}', color: Colors.white),
                StatPill(icon: Icons.paid_rounded, value: Formatters.count(c.gold), color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white54, width: 1.5),
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}
