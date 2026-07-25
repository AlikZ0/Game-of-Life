import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/streak_providers.dart';

/// Compact streak indicator for the dashboard app bar: a flame + day count.
/// Tapping opens the milestones screen.
class StreakFlame extends ConsumerWidget {
  const StreakFlame({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final count = streak.valueOrNull?.current ?? 0;
    final active = count > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.pushNamed(AppRoute.streaks.name),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: active ? AppColors.warning : Theme.of(context).colorScheme.outline,
              size: 22,
            ),
            const SizedBox(width: 2),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: active ? AppColors.warning : null,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
