import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/boss.dart';
import 'hp_bar.dart';

/// A boss summary card for the list: portrait, name, HP bar, and reward.
class BossCard extends StatelessWidget {
  const BossCard({super.key, required this.boss, required this.onTap});

  final Boss boss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.rLg,
          border: Border.all(color: scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: boss.isDefeated
                      ? [AppColors.success, AppColors.secondary]
                      : [AppColors.tertiary, AppColors.accentDeep],
                ),
              ),
              child: Center(
                child: Icon(
                  boss.isDefeated ? Icons.emoji_events_rounded : Icons.local_fire_department_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(boss.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (boss.deadline != null)
                        Text(
                          Formatters.countdown(boss.deadline!.difference(DateTime.now())),
                          style: text.labelSmall,
                        ),
                    ],
                  ),
                  AppSpacing.vMd,
                  HpBar(fraction: boss.hpFraction, height: 14),
                  AppSpacing.gapXs,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${Formatters.count(boss.currentHp)} / ${Formatters.count(boss.maxHp)} HP',
                          style: text.labelSmall),
                      Text('${Formatters.percent(boss.progress)} down', style: text.labelSmall),
                    ],
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
