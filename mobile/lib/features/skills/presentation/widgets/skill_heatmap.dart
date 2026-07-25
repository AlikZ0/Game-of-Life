import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/skill.dart';

/// A GitHub-style contribution heatmap of daily skill XP over the last ~13
/// weeks. Custom-painted with a simple weeks × 7 grid for a crisp, dependency
/// -light result.
class SkillHeatmap extends StatelessWidget {
  const SkillHeatmap({super.key, required this.cells, this.weeks = 13});

  final List<SkillHeatCell> cells;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final byDay = {for (final c in cells) _key(c.day): c.xp};
    final maxXp = cells.fold<int>(1, (m, c) => c.xp > m ? c.xp : m);

    final today = DateTime.now();
    final start = today.subtract(Duration(days: weeks * 7 - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity', style: Theme.of(context).textTheme.titleSmall),
        AppSpacing.vMd,
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 3.0;
            final cell = ((constraints.maxWidth - (weeks - 1) * gap) / weeks).clamp(6.0, 18.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var w = 0; w < weeks; w++) ...[
                  Column(
                    children: [
                      for (var d = 0; d < 7; d++)
                        Padding(
                          padding: EdgeInsets.only(bottom: gap),
                          child: _Cell(
                            size: cell,
                            intensity: _intensity(byDay, start, w, d, maxXp),
                            base: scheme.surfaceContainerHighest,
                          ),
                        ),
                    ],
                  ),
                  if (w < weeks - 1) SizedBox(width: gap),
                ],
              ],
            );
          },
        ),
        AppSpacing.vMd,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Less', style: Theme.of(context).textTheme.labelSmall),
            AppSpacing.hSm,
            for (final i in [0.15, 0.4, 0.7, 1.0])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _Cell(size: 12, intensity: i, base: scheme.surfaceContainerHighest),
              ),
            AppSpacing.hSm,
            Text('More', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }

  double _intensity(Map<String, int> byDay, DateTime start, int w, int d, int maxXp) {
    final date = start.add(Duration(days: w * 7 + d));
    if (date.isAfter(DateTime.now())) return 0;
    final xp = byDay[_key(date)] ?? 0;
    return xp == 0 ? 0 : (xp / maxXp).clamp(0.12, 1.0);
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class _Cell extends StatelessWidget {
  const _Cell({required this.size, required this.intensity, required this.base});
  final double size;
  final double intensity;
  final Color base;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: intensity == 0
            ? base
            : Color.lerp(AppColors.accent.withValues(alpha: 0.25), AppColors.accent, intensity),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
