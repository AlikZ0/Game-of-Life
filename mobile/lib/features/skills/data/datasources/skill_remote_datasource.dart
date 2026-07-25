import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/skill.dart';
import '../models/skill_model.dart';

class SkillRemoteDataSource {
  const SkillRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<SkillModel>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.skills);
    final items = (res.data?['data'] ?? res.data?['skills'] ?? const []) as List<dynamic>;
    return items.map((e) => SkillModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Last-90-days XP-per-day series for the heatmap.
  Future<List<SkillHeatCell>> history(String skillId) async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.skillHistory(skillId));
    final items = (res.data?['data'] ?? const []) as List<dynamic>;
    return items.map((e) {
      final map = e as Map<String, dynamic>;
      return SkillHeatCell(
        day: DateTime.parse(map['day'] as String),
        xp: (map['xp'] as num).toInt(),
      );
    }).toList();
  }
}
