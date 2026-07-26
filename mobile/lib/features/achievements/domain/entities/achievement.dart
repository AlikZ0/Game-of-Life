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
    required this.unlocked,
    this.criteria,
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

  /// Whether the character has unlocked this achievement.
  final bool unlocked;

  /// The raw unlock criteria (metric/threshold), as delivered by the API.
  final Map<String, dynamic>? criteria;
  final bool isSecret;

  bool get isUnlocked => unlocked || progress >= 1;

  Color get rarityColor => AppColors.rarity[rarity] ?? AppColors.rarity['BRONZE']!;
}
