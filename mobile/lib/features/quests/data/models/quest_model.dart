import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/quest.dart';
import '../../domain/entities/quest_enums.dart';

part 'quest_model.freezed.dart';
part 'quest_model.g.dart';

/// DTO for the API `Quest` resource.
@freezed
class QuestModel with _$QuestModel {
  const QuestModel._();

  const factory QuestModel({
    required String id,
    required String title,
    String? description,
    @Default('DAILY') String cadence,
    @Default('MEDIUM') String difficulty,
    @Default('ACTIVE') String status,
    @JsonKey(name: 'xpReward') @Default(20) int xpReward,
    @JsonKey(name: 'goldReward') @Default(10) int goldReward,
    @JsonKey(name: 'skillKey') String? skillKey,
    @JsonKey(name: 'energyCost') @Default(10) int energyCost,
    @JsonKey(name: 'bossId') String? bossId,
    @Default(10) int damage,
    @JsonKey(name: 'dueAt') DateTime? dueAt,
    @JsonKey(name: 'completedForPeriod') @Default(false) bool completedForPeriod,
  }) = _QuestModel;

  factory QuestModel.fromJson(Map<String, dynamic> json) => _$QuestModelFromJson(json);

  Quest toEntity() => Quest(
        id: id,
        title: title,
        description: description,
        cadence: QuestCadence.fromApi(cadence),
        difficulty: QuestDifficulty.fromApi(difficulty),
        status: QuestStatus.fromApi(status),
        xpReward: xpReward,
        goldReward: goldReward,
        skillKey: skillKey,
        energyCost: energyCost,
        bossId: bossId,
        damage: damage,
        dueAt: dueAt,
        completedForPeriod: completedForPeriod,
      );
}
