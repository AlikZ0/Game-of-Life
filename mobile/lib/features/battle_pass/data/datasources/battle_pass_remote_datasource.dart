import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/battle_pass_models.dart';

class BattlePassRemoteDataSource {
  const BattlePassRemoteDataSource(this._dio);
  final Dio _dio;

  Future<BattlePassResponseModel> current() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.battlePass);
    final data = (res.data?['data'] ?? res.data ?? const {}) as Map<String, dynamic>;
    return BattlePassResponseModel.fromJson(data);
  }

  Future<void> claim(int tier) => _dio.post<void>(ApiEndpoints.claimBattlePassTier(tier));
}
