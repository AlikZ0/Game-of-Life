import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../character/presentation/providers/character_providers.dart';
import '../../data/models/economy_models.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/shop_reward.dart';

final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.inventory);
  final items = (res.data?['data'] ?? const []) as List<dynamic>;
  return items
      .map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>).toEntity())
      .toList();
});

final shopRewardsProvider = FutureProvider<List<ShopReward>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.shop);
  final items = (res.data?['data'] ?? const []) as List<dynamic>;
  return items
      .map((e) => ShopRewardModel.fromJson(e as Map<String, dynamic>).toEntity())
      .toList();
});

/// Redeems a shop reward (spends gold). Refreshes the character header + list.
final redeemRewardProvider = Provider((ref) => _RedeemReward(ref));

class _RedeemReward {
  const _RedeemReward(this._ref);
  final Ref _ref;

  Future<void> call(String rewardId) async {
    final Dio dio = _ref.read(dioProvider);
    await dio.post<void>(ApiEndpoints.redeemReward(rewardId));
    _ref.invalidate(shopRewardsProvider);
    _ref.invalidate(myCharacterProvider);
  }
}
