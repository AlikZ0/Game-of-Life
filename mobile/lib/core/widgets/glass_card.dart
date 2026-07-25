import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A frosted, rounded surface used as the base container throughout the app.
///
/// On dark surfaces it applies a subtle blur + translucent fill to create the
/// premium glassmorphic feel; falls back to a solid rounded card when [blur]
/// is disabled.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
    this.blur = true,
    this.gradient,
    this.borderRadius = AppRadius.rLg,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool blur;
  final Gradient? gradient;
  final BorderRadius borderRadius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surface;

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? surface.withValues(alpha: blur ? 0.72 : 1) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: border
            ? Border.all(color: scheme.outline.withValues(alpha: 0.6), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    final card = ClipRRect(
      borderRadius: borderRadius,
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: content,
            )
          : content,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
