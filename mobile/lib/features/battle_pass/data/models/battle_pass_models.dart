import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/battle_pass.dart';

part 'battle_pass_models.freezed.dart';
part 'battle_pass_models.g.dart';

@freezed
class BattlePassResponseModel with _$BattlePassResponseModel {
  const BattlePassResponseModel._();

  const factory BattlePassResponseModel({
    SeasonModel? season,
    @Default(<BattlePassTierModel>[]) List<BattlePassTierModel> tiers,
    BattlePassProgressModel? progress,
  }) = _BattlePassResponseModel;

  factory BattlePassResponseModel.fromJson(Map<String, dynamic> json) =>
      _$BattlePassResponseModelFromJson(json);

  BattlePass toEntity() {
    final p = progress ?? const BattlePassProgressModel();
    return BattlePass(
      seasonName: season?.name ?? 'Season',
      endAt: season?.endAt ?? DateTime.now(),
      currentTier: p.tier,
      xp: p.xp,
      isPremium: p.isPremium,
      claimedTiers: p.claimedTiers,
      tiers: tiers.map((t) => t.toEntity()).toList(),
    );
  }
}

@freezed
class SeasonModel with _$SeasonModel {
  const factory SeasonModel({
    required String id,
    @Default('Season') String name,
    @JsonKey(name: 'startAt') DateTime? startAt,
    @JsonKey(name: 'endAt') DateTime? endAt,
  }) = _SeasonModel;

  factory SeasonModel.fromJson(Map<String, dynamic> json) => _$SeasonModelFromJson(json);
}

@freezed
class BattlePassTierModel with _$BattlePassTierModel {
  const BattlePassTierModel._();

  const factory BattlePassTierModel({
    required int tier,
    @JsonKey(name: 'xpRequired') @Default(0) int xpRequired,
    @JsonKey(name: 'freeReward') Object? freeReward,
    @JsonKey(name: 'premiumReward') Object? premiumReward,
  }) = _BattlePassTierModel;

  factory BattlePassTierModel.fromJson(Map<String, dynamic> json) =>
      _$BattlePassTierModelFromJson(json);

  BattlePassTier toEntity() => BattlePassTier(
        tier: tier,
        xpRequired: xpRequired,
        freeReward: _rewardLabel(freeReward),
        premiumReward: _rewardLabel(premiumReward),
      );
}

@freezed
class BattlePassProgressModel with _$BattlePassProgressModel {
  const factory BattlePassProgressModel({
    @Default(0) int xp,
    @Default(0) int tier,
    @JsonKey(name: 'isPremium') @Default(false) bool isPremium,
    @JsonKey(name: 'claimedTiers') @Default(<int>[]) List<int> claimedTiers,
  }) = _BattlePassProgressModel;

  factory BattlePassProgressModel.fromJson(Map<String, dynamic> json) =>
      _$BattlePassProgressModelFromJson(json);
}

/// Rewards may arrive as a bare refKey string or a nested reward object; reduce
/// either to a short display label.
String? _rewardLabel(Object? raw) => switch (raw) {
      null => null,
      String s => s,
      Map<String, dynamic> m =>
        (m['name'] ?? m['refKey'] ?? m['label'] ?? m['itemType'])?.toString(),
      _ => raw.toString(),
    };
