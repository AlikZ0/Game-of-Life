import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/character.dart';
import '../../domain/entities/character_class.dart';

part 'character_model.freezed.dart';
part 'character_model.g.dart';

/// DTO for the API `Character` resource. `totalXp` is a BigInt server-side and
/// arrives as a numeric string/number — parsed leniently into an int.
@freezed
class CharacterModel with _$CharacterModel {
  const CharacterModel._();

  const factory CharacterModel({
    required String id,
    required String name,
    @JsonKey(name: 'avatarKey') @Default('default') String avatarKey,
    @JsonKey(name: 'class') @Default('RANGER') String characterClass,
    @Default(1) int level,
    @Default(0) int xp,
    @JsonKey(name: 'totalXp', fromJson: _toInt) @Default(0) int totalXp,
    @Default(0) int gold,
    @Default(100) int hp,
    @JsonKey(name: 'maxHp') @Default(100) int maxHp,
    @Default(100) int energy,
    @JsonKey(name: 'maxEnergy') @Default(100) int maxEnergy,
    @JsonKey(name: 'activeTitle') String? activeTitle,
  }) = _CharacterModel;

  factory CharacterModel.fromJson(Map<String, dynamic> json) =>
      _$CharacterModelFromJson(json);

  Character toEntity() => Character(
        id: id,
        name: name,
        avatarKey: avatarKey,
        characterClass: CharacterClassType.fromApi(characterClass),
        level: level,
        xp: xp,
        totalXp: totalXp,
        gold: gold,
        hp: hp,
        maxHp: maxHp,
        energy: energy,
        maxEnergy: maxEnergy,
        activeTitle: activeTitle,
      );
}

int _toInt(dynamic value) => switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };
