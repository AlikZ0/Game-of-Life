import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/boss.dart';

part 'boss_model.freezed.dart';
part 'boss_model.g.dart';

@freezed
class BossModel with _$BossModel {
  const BossModel._();

  const factory BossModel({
    required String id,
    required String name,
    String? description,
    @JsonKey(name: 'imageKey') @Default('boss_default') String imageKey,
    @JsonKey(name: 'maxHp') required int maxHp,
    @JsonKey(name: 'currentHp') required int currentHp,
    @Default('ACTIVE') String status,
    @JsonKey(name: 'rewardXp') @Default(500) int rewardXp,
    @JsonKey(name: 'rewardGold') @Default(250) int rewardGold,
    DateTime? deadline,
  }) = _BossModel;

  factory BossModel.fromJson(Map<String, dynamic> json) => _$BossModelFromJson(json);

  Boss toEntity() => Boss(
        id: id,
        name: name,
        description: description,
        imageKey: imageKey,
        maxHp: maxHp,
        currentHp: currentHp,
        status: status,
        rewardXp: rewardXp,
        rewardGold: rewardGold,
        deadline: deadline,
      );
}
