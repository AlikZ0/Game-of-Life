import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/streak.dart';

part 'streak_model.freezed.dart';
part 'streak_model.g.dart';

@freezed
class StreakModel with _$StreakModel {
  const StreakModel._();

  const factory StreakModel({
    @Default(0) int current,
    @Default(0) int longest,
    @JsonKey(name: 'freezeCount') @Default(0) int freezeCount,
    @JsonKey(name: 'lastActiveDay') String? lastActiveDay,
  }) = _StreakModel;

  factory StreakModel.fromJson(Map<String, dynamic> json) => _$StreakModelFromJson(json);

  Streak toEntity() => Streak(
        current: current,
        longest: longest,
        freezeCount: freezeCount,
        lastActiveDay: lastActiveDay,
      );
}
