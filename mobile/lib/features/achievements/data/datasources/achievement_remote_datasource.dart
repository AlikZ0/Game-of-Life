import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/achievement_model.dart';

class AchievementRemoteDataSource {
  const AchievementRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<AchievementModel>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.achievements);
    final items = (res.data?['data'] ?? res.data?['achievements'] ?? const []) as List<dynamic>;
    return items.map((e) => AchievementModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
