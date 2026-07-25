import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Mirrors Prisma `Difficulty`. Carries a multiplier used to preview scaled
/// rewards and a display color.
enum QuestDifficulty {
  trivial('TRIVIAL', 'Trivial', 0.5),
  easy('EASY', 'Easy', 0.8),
  medium('MEDIUM', 'Medium', 1.0),
  hard('HARD', 'Hard', 1.5),
  epic('EPIC', 'Epic', 2.5);

  const QuestDifficulty(this.apiValue, this.label, this.multiplier);

  final String apiValue;
  final String label;
  final double multiplier;

  Color get color => AppColors.difficulty[apiValue] ?? AppColors.info;

  static QuestDifficulty fromApi(String v) =>
      values.firstWhere((d) => d.apiValue == v, orElse: () => QuestDifficulty.medium);
}

/// Mirrors Prisma `QuestCadence`.
enum QuestCadence {
  daily('DAILY', 'Daily', Icons.wb_sunny_rounded),
  weekly('WEEKLY', 'Weekly', Icons.calendar_view_week_rounded),
  monthly('MONTHLY', 'Monthly', Icons.calendar_month_rounded),
  oneOff('ONE_OFF', 'One-off', Icons.flag_rounded);

  const QuestCadence(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;

  static QuestCadence fromApi(String v) =>
      values.firstWhere((c) => c.apiValue == v, orElse: () => QuestCadence.daily);
}

/// Mirrors Prisma `QuestStatus`.
enum QuestStatus {
  active('ACTIVE'),
  completed('COMPLETED'),
  archived('ARCHIVED');

  const QuestStatus(this.apiValue);
  final String apiValue;

  static QuestStatus fromApi(String v) =>
      values.firstWhere((s) => s.apiValue == v, orElse: () => QuestStatus.active);
}
