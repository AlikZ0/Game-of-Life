import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/economy_models.dart';

class EconomyRemoteDataSource {
  const EconomyRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<InventoryItemModel>> inventory() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.inventory);
    final items = (res.data?['data'] ?? const []) as List<dynamic>;
    return items.map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ShopRewardModel>> shop() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.shop);
    final items = (res.data?['data'] ?? const []) as List<dynamic>;
    return items.map((e) => ShopRewardModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Redeems a shop reward and returns the character's new gold balance.
  Future<int> redeem(String rewardId) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.redeemReward(rewardId));
    final data = (res.data?['data'] ?? res.data ?? const {}) as Map<String, dynamic>;
    return (data['goldBalance'] as num?)?.toInt() ?? 0;
  }
}
