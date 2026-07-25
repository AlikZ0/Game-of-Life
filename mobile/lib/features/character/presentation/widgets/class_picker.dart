import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/character_class.dart';

/// Horizontal, selectable class cards for the creation flow.
class ClassPicker extends StatelessWidget {
  const ClassPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CharacterClassType selected;
  final ValueChanged<CharacterClassType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        itemCount: CharacterClassType.values.length,
        separatorBuilder: (_, __) => AppSpacing.hMd,
        itemBuilder: (context, i) {
          final c = CharacterClassType.values[i];
          return _ClassCard(
            type: c,
            isSelected: c == selected,
            onTap: () => onSelected(c),
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final CharacterClassType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 136,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: isSelected ? type.gradient : null,
          color: isSelected ? null : scheme.surface,
          borderRadius: AppRadius.rLg,
          border: Border.all(
            color: isSelected ? Colors.transparent : scheme.outline,
            width: 1.4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: type.color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              type.icon,
              size: 34,
              color: isSelected ? Colors.white : type.color,
            ),
            const Spacer(),
            Text(
              type.label,
              style: text.titleMedium?.copyWith(
                color: isSelected ? Colors.white : scheme.onSurface,
              ),
            ),
            AppSpacing.gapXs,
            Text(
              type.tagline,
              style: text.bodySmall?.copyWith(
                color: isSelected ? Colors.white70 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
