import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A hexagonal-feeling gradient badge showing a character/skill level.
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    this.size = 44,
    this.gradient = AppColors.heroGradient,
  });

  final int level;
  final double size;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$level',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.36,
              height: 1,
            ),
          ),
          Text(
            'LVL',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              fontSize: size * 0.16,
              letterSpacing: 1,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
