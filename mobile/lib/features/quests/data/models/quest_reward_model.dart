import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/quest_reward.dart';

part 'quest_reward_model.freezed.dart';
part 'quest_reward_model.g.dart';

/// DTO for the completion reward envelope returned by `/quests/:id/complete`.
@freezed
class QuestRewardModel with _$QuestRewardModel {
  const QuestRewardModel._();

  const factory QuestRewardModel({
    @JsonKey(name: 'xpAwarded') @Default(0) int xpAwarded,
    @JsonKey(name: 'goldAwarded') @Default(0) int goldAwarded,
    @JsonKey(name: 'leveledUp') @Default(false) bool leveledUp,
    @JsonKey(name: 'newLevel') @Default(0) int newLevel,
    @JsonKey(name: 'skillKey') String? skillKey,
    @JsonKey(name: 'skillXp') @Default(0) int skillXp,
    @JsonKey(name: 'bossDamage') @Default(0) int bossDamage,
    @JsonKey(name: 'bossDefeated') @Default(false) bool bossDefeated,
    @JsonKey(name: 'streakCount') @Default(0) int streakCount,
  }) = _QuestRewardModel;

  factory QuestRewardModel.fromJson(Map<String, dynamic> json) =>
      _$QuestRewardModelFromJson(json);

  QuestReward toEntity() => QuestReward(
        xpAwarded: xpAwarded,
        goldAwarded: goldAwarded,
        leveledUp: leveledUp,
        newLevel: newLevel,
        skillKey: skillKey,
        skillXp: skillXp,
        bossDamage: bossDamage,
        bossDefeated: bossDefeated,
        streakCount: streakCount,
      );
}
