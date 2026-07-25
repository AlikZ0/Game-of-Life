import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/shop_reward.dart';

part 'economy_models.freezed.dart';
part 'economy_models.g.dart';

@freezed
class InventoryItemModel with _$InventoryItemModel {
  const InventoryItemModel._();

  const factory InventoryItemModel({
    required String id,
    @JsonKey(name: 'itemType') @Default('COSMETIC_AVATAR') String itemType,
    @JsonKey(name: 'refKey') @Default('') String refKey,
    @Default('') String name,
    @Default(1) int quantity,
    @Default(false) bool equipped,
  }) = _InventoryItemModel;

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemModelFromJson(json);

  InventoryItem toEntity() => InventoryItem(
        id: id,
        itemType: itemType,
        refKey: refKey,
        name: name,
        quantity: quantity,
        equipped: equipped,
      );
}

@freezed
class ShopRewardModel with _$ShopRewardModel {
  const ShopRewardModel._();

  const factory ShopRewardModel({
    required String id,
    required String title,
    String? description,
    @Default('gift') String icon,
    @JsonKey(name: 'goldCost') @Default(0) int goldCost,
    int? stock,
    @JsonKey(name: 'timesRedeemed') @Default(0) int timesRedeemed,
    @JsonKey(name: 'isActive') @Default(true) bool isActive,
  }) = _ShopRewardModel;

  factory ShopRewardModel.fromJson(Map<String, dynamic> json) =>
      _$ShopRewardModelFromJson(json);

  ShopReward toEntity() => ShopReward(
        id: id,
        title: title,
        description: description,
        icon: icon,
        goldCost: goldCost,
        stock: stock,
        timesRedeemed: timesRedeemed,
        isActive: isActive,
      );
}
