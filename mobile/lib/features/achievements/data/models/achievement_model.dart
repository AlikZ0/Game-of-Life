import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/achievement.dart';

part 'achievement_model.freezed.dart';
part 'achievement_model.g.dart';

@freezed
class AchievementModel with _$AchievementModel {
  const AchievementModel._();

  const factory AchievementModel({
    required String id,
    required String name,
    @Default('') String description,
    @Default('BRONZE') String rarity,
    @Default('trophy') String icon,
    @Default('meta') String category,
    @JsonKey(name: 'rewardXp') @Default(0) int rewardXp,
    @JsonKey(name: 'rewardGold') @Default(0) int rewardGold,
    @Default(0) double progress,
    @JsonKey(name: 'unlockedAt') DateTime? unlockedAt,
    @JsonKey(name: 'isSecret') @Default(false) bool isSecret,
  }) = _AchievementModel;

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      _$AchievementModelFromJson(json);

  Achievement toEntity() => Achievement(
        id: id,
        name: name,
        description: description,
        rarity: rarity,
        icon: icon,
        category: category,
        rewardXp: rewardXp,
        rewardGold: rewardGold,
        progress: progress,
        unlockedAt: unlockedAt,
        isSecret: isSecret,
      );
}
