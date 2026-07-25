import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// An animated, rounded progress bar for XP / skill / battle-pass progress.
class XpBar extends StatelessWidget {
  const XpBar({
    super.key,
    required this.value,
    this.height = 10,
    this.gradient = AppColors.accentGradient,
    this.background,
    this.label,
  });

  /// Progress in the range 0..1.
  final double value;
  final double height;
  final Gradient gradient;
  final Color? background;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.labelSmall),
          AppSpacing.gapXs,
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Stack(
            children: [
              Container(
                height: height,
                color: background ?? scheme.surfaceContainerHighest,
              ),
              LayoutBuilder(
                builder: (context, constraints) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value.clamp(0, 1)),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Container(
                    height: height,
                    width: constraints.maxWidth * v,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(height),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
