import 'dart:math' as math;

import 'character_class.dart';

/// Core domain entity for the player's character. Mirrors the Prisma
/// `Character` model. Includes derived progression helpers used across the app.
class Character {
  const Character({
    required this.id,
    required this.name,
    required this.avatarKey,
    required this.characterClass,
    required this.level,
    required this.xp,
    required this.totalXp,
    required this.gold,
    required this.hp,
    required this.maxHp,
    required this.energy,
    required this.maxEnergy,
    this.activeTitle,
  });

  final String id;
  final String name;
  final String avatarKey;
  final CharacterClassType characterClass;

  final int level;

  /// XP earned within the current level.
  final int xp;
  final int totalXp;
  final int gold;
  final int hp;
  final int maxHp;
  final int energy;
  final int maxEnergy;
  final String? activeTitle;

  /// XP required to advance from [level] to the next, using the exponential
  /// curve defined in the game-design doc: `100 * level^1.5`.
  int get xpForNextLevel => (100 * math.pow(level, 1.5)).round();

  /// Progress toward the next level, 0..1.
  double get levelProgress {
    final needed = xpForNextLevel;
    if (needed <= 0) return 0;
    return (xp / needed).clamp(0.0, 1.0);
  }

  double get hpFraction => maxHp == 0 ? 0 : (hp / maxHp).clamp(0.0, 1.0);
  double get energyFraction => maxEnergy == 0 ? 0 : (energy / maxEnergy).clamp(0.0, 1.0);

  Character copyWith({
    int? level,
    int? xp,
    int? totalXp,
    int? gold,
    int? hp,
    int? energy,
    String? activeTitle,
  }) =>
      Character(
        id: id,
        name: name,
        avatarKey: avatarKey,
        characterClass: characterClass,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        totalXp: totalXp ?? this.totalXp,
        gold: gold ?? this.gold,
        hp: hp ?? this.hp,
        maxHp: maxHp,
        energy: energy ?? this.energy,
        maxEnergy: maxEnergy,
        activeTitle: activeTitle ?? this.activeTitle,
      );
}
