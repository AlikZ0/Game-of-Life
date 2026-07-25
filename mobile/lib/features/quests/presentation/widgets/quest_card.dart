import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/quest.dart';

/// A single quest row with a tappable completion checkbox, difficulty tag, and
/// reward chips. Completing animates the check + strikes through the title.
class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.quest,
    required this.onToggleComplete,
    this.onTap,
  });

  final Quest quest;
  final VoidCallback onToggleComplete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final done = quest.completedForPeriod;

    return Opacity(
      opacity: done ? 0.6 : 1,
      child: Material(
        color: scheme.surface,
        borderRadius: AppRadius.rLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.rLg,
              border: Border.all(color: scheme.outline),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                _CompleteButton(done: done, color: quest.difficulty.color, onTap: onToggleComplete),
                AppSpacing.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: text.titleSmall?.copyWith(
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.gapXs,
                      Row(
                        children: [
                          _Tag(
                            label: quest.difficulty.label,
                            color: quest.difficulty.color,
                          ),
                          AppSpacing.hSm,
                          Icon(quest.cadence.icon, size: 13, color: scheme.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(quest.cadence.label, style: text.labelSmall),
                          if (quest.isLinkedToBoss) ...[
                            AppSpacing.hSm,
                            const Icon(Icons.local_fire_department_rounded,
                                size: 13, color: AppColors.tertiary),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.hSm,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Reward(icon: Icons.bolt_rounded, value: quest.scaledXp, color: AppColors.xp),
                    const SizedBox(height: 4),
                    _Reward(icon: Icons.paid_rounded, value: quest.scaledGold, color: AppColors.gold),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({required this.done, required this.color, required this.onTap});
  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          color: done ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: done
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.rPill,
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Reward extends StatelessWidget {
  const _Reward({required this.icon, required this.value, required this.color});
  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          Formatters.compact(value),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
