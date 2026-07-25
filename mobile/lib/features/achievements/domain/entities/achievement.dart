import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Domain entity combining Prisma `Achievement` + `CharacterAchievement`
/// progress, so the gallery can render both locked and unlocked states.
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.icon,
    required this.category,
    required this.rewardXp,
    required this.rewardGold,
    required this.progress,
    this.unlockedAt,
    this.isSecret = false,
  });

  final String id;
  final String name;
  final String description;
  final String rarity; // BRONZE | SILVER | GOLD | LEGENDARY
  final String icon;
  final String category;
  final int rewardXp;
  final int rewardGold;

  /// 0..1 completion for tiered achievements.
  final double progress;
  final DateTime? unlockedAt;
  final bool isSecret;

  bool get isUnlocked => unlockedAt != null || progress >= 1;

  Color get rarityColor => AppColors.rarity[rarity] ?? AppColors.rarity['BRONZE']!;
}
