import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/xp_bar.dart';
import '../../domain/entities/skill.dart';

/// A skill row: colored icon badge, name, level, and a progress bar.
class SkillTile extends StatelessWidget {
  const SkillTile({super.key, required this.skill});
  final Skill skill;

  static const _iconMap = <String, IconData>{
    'bolt': Icons.bolt_rounded,
    'code': Icons.code_rounded,
    'fitness': Icons.fitness_center_rounded,
    'reading': Icons.menu_book_rounded,
    'english': Icons.translate_rounded,
    'business': Icons.business_center_rounded,
    'finance': Icons.savings_rounded,
    'leadership': Icons.groups_rounded,
    'discipline': Icons.self_improvement_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final icon = _iconMap[skill.icon] ?? Icons.bolt_rounded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: skill.color.withValues(alpha: 0.16),
              borderRadius: AppRadius.rMd,
            ),
            child: Icon(icon, color: skill.color),
          ),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(skill.name, style: text.titleSmall)),
                    Text('Lvl ${skill.level}',
                        style: text.labelMedium?.copyWith(color: skill.color)),
                  ],
                ),
                AppSpacing.gapSm,
                XpBar(
                  value: skill.progress,
                  height: 8,
                  gradient: LinearGradient(colors: [skill.color, skill.color.withValues(alpha: 0.6)]),
                ),
                AppSpacing.gapXs,
                Text(
                  '${Formatters.count(skill.xp)} / ${Formatters.count(skill.xpForNextLevel)} XP',
                  style: text.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
