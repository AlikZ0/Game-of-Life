import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A compact icon + value chip used for HP / Energy / Gold / XP readouts.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.label,
  });

  final IconData icon;
  final String value;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.rPill,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          AppSpacing.hSm,
          Text(
            value,
            style: text.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(label!, style: text.labelSmall?.copyWith(color: color)),
          ],
        ],
      ),
    );
  }
}
