import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/stats_dashboard.dart';

part 'stats_models.freezed.dart';
part 'stats_models.g.dart';

@freezed
class StatsDashboardModel with _$StatsDashboardModel {
  const StatsDashboardModel._();

  const factory StatsDashboardModel({
    @Default(1) int level,
    @JsonKey(name: 'totalXp', fromJson: _toInt) @Default(0) int totalXp,
    @Default(0) int gold,
    @JsonKey(name: 'questsCompleted30d') @Default(0) int questsCompleted30d,
    @JsonKey(name: 'activeQuests') @Default(0) int activeQuests,
    @JsonKey(name: 'currentStreak') @Default(0) int currentStreak,
    @JsonKey(name: 'longestStreak') @Default(0) int longestStreak,
    @JsonKey(name: 'skillBalance') @Default(<SkillBalanceModel>[]) List<SkillBalanceModel> skillBalance,
  }) = _StatsDashboardModel;

  factory StatsDashboardModel.fromJson(Map<String, dynamic> json) =>
      _$StatsDashboardModelFromJson(json);

  StatsDashboard toEntity() => StatsDashboard(
        level: level,
        totalXp: totalXp,
        gold: gold,
        questsCompleted30d: questsCompleted30d,
        activeQuests: activeQuests,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        skillBalance: skillBalance.map((s) => s.toEntity()).toList(),
      );
}

@freezed
class SkillBalanceModel with _$SkillBalanceModel {
  const SkillBalanceModel._();

  const factory SkillBalanceModel({
    required String key,
    required String name,
    @Default(1) int level,
    @JsonKey(name: 'totalXp', fromJson: _toInt) @Default(0) int totalXp,
  }) = _SkillBalanceModel;

  factory SkillBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$SkillBalanceModelFromJson(json);

  SkillBalance toEntity() => SkillBalance(
        key: key,
        name: name,
        level: level,
        totalXp: totalXp,
      );
}

/// Coerces `totalXp` (delivered as a BigInt string) into an int.
int _toInt(dynamic value) => switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };
