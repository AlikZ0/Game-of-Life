import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/skill.dart';

part 'skill_model.freezed.dart';
part 'skill_model.g.dart';

@freezed
class SkillModel with _$SkillModel {
  const SkillModel._();

  const factory SkillModel({
    required String id,
    required String key,
    required String name,
    @Default('bolt') String icon,
    @Default('#7C5CFF') String color,
    @Default(1) int level,
    @Default(0) int xp,
    @JsonKey(name: 'totalXp', fromJson: _toInt) @Default(0) int totalXp,
  }) = _SkillModel;

  factory SkillModel.fromJson(Map<String, dynamic> json) => _$SkillModelFromJson(json);

  Skill toEntity() => Skill(
        id: id,
        key: key,
        name: name,
        icon: icon,
        color: _parseColor(color),
        level: level,
        xp: xp,
        totalXp: totalXp,
      );
}

int _toInt(dynamic value) => switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };

Color _parseColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16) ?? 0x7C5CFF;
  return Color(cleaned.length <= 6 ? 0xFF000000 | value : value);
}
