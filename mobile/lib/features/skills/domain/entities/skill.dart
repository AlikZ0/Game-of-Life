import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Domain entity for a Skill. Mirrors Prisma `Skill`.
class Skill {
  const Skill({
    required this.id,
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.level,
    required this.xp,
    required this.totalXp,
  });

  final String id;
  final String key;
  final String name;
  final String icon; // icon name from the API catalog
  final Color color;
  final int level;
  final int xp;
  final int totalXp;

  /// XP needed for the next skill level: `80 * level^1.4`.
  int get xpForNextLevel => (80 * math.pow(level, 1.4)).round();

  double get progress {
    final needed = xpForNextLevel;
    return needed <= 0 ? 0 : (xp / needed).clamp(0.0, 1.0);
  }
}

/// A single day's XP total for the skill activity heatmap.
class SkillHeatCell {
  const SkillHeatCell({required this.day, required this.xp});
  final DateTime day;
  final int xp;
}

/// A single XP-award event in a skill's history. Mirrors Prisma `SkillEvent`.
class SkillEvent {
  const SkillEvent({
    required this.id,
    required this.skillId,
    required this.amount,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final String skillId;
  final int amount;
  final String source;
  final DateTime createdAt;
}

/// The XP-event history for a single skill, keyed by skill key.
class SkillHistory {
  const SkillHistory({required this.skillKey, required this.events});
  final String skillKey;
  final List<SkillEvent> events;
}
