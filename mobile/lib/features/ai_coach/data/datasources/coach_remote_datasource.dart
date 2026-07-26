import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/coach_models.dart';

class CoachRemoteDataSource {
  const CoachRemoteDataSource(this._dio);
  final Dio _dio;

  Future<CoachAnalysisModel> analyze() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.coachAnalyze);
    final data = (res.data?['data'] ?? res.data ?? const {}) as Map<String, dynamic>;
    return CoachAnalysisModel.fromJson(data);
  }
}
