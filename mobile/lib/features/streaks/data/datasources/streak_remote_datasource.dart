import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/streak_model.dart';

class StreakRemoteDataSource {
  const StreakRemoteDataSource(this._dio);
  final Dio _dio;

  Future<StreakModel> me() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.streak);
    final data = (res.data?['data'] ?? res.data ?? const {}) as Map<String, dynamic>;
    return StreakModel.fromJson(data);
  }
}
