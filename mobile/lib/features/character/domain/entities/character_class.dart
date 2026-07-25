import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Playable classes — mirrors the Prisma `CharacterClass` enum, enriched with
/// presentation metadata (icon, accent, tagline) for the class picker.
enum CharacterClassType {
  warrior('WARRIOR', 'Warrior', 'Discipline & fitness', Icons.fitness_center_rounded, Color(0xFFFF7A9A)),
  mage('MAGE', 'Mage', 'Knowledge & study', Icons.auto_stories_rounded, Color(0xFF7C5CFF)),
  rogue('ROGUE', 'Rogue', 'Finance & business', Icons.savings_rounded, Color(0xFF35D0BA)),
  ranger('RANGER', 'Ranger', 'Balance & lifestyle', Icons.forest_rounded, Color(0xFF3ED598)),
  paladin('PALADIN', 'Paladin', 'Leadership & social', Icons.shield_rounded, Color(0xFFFFC848));

  const CharacterClassType(this.apiValue, this.label, this.tagline, this.icon, this.color);

  /// Value sent to / received from the API.
  final String apiValue;
  final String label;
  final String tagline;
  final IconData icon;
  final Color color;

  static CharacterClassType fromApi(String value) => values.firstWhere(
        (c) => c.apiValue == value,
        orElse: () => CharacterClassType.ranger,
      );

  Gradient get gradient => LinearGradient(
        colors: [color, Color.lerp(color, AppColors.accent, 0.4)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
