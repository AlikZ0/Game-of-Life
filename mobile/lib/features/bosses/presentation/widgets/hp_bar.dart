import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A chunky, animated HP bar for bosses. Red gradient, rounded, with an inner
/// highlight for a game-y feel.
class HpBar extends StatelessWidget {
  const HpBar({
    super.key,
    required this.fraction,
    this.height = 18,
    this.showShine = true,
  });

  final double fraction;
  final double height;
  final bool showShine;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: Colors.black.withValues(alpha: 0.35)),
          LayoutBuilder(
            builder: (context, constraints) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Container(
                height: height,
                width: constraints.maxWidth * v,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.danger, Color(0xFFFF8A5B)],
                  ),
                ),
                child: showShine
                    ? Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: height * 0.35,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(height),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
