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

  /// Aggregated XP-per-day series across all skills for the activity heatmap.
  Future<List<SkillHeatCell>> heatmap({int days = 90}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.skillsHeatmap,
      queryParameters: {'days': days},
    );
    final items = (res.data?['data'] ?? const []) as List<dynamic>;
    return items.map((e) {
      final map = e as Map<String, dynamic>;
      return SkillHeatCell(
        day: DateTime.parse(map['date'] as String),
        xp: (map['xp'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  /// Per-skill XP-event history, keyed by the skill's KEY (not id).
  Future<SkillHistory> history(String skillKey) async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.skillHistory(skillKey));
    final data = (res.data?['data'] ?? res.data ?? const {}) as Map<String, dynamic>;
    final events = (data['events'] ?? const []) as List<dynamic>;
    return SkillHistory(
      skillKey: data['skillKey'] as String? ?? skillKey,
      events: events.map((e) {
        final map = e as Map<String, dynamic>;
        return SkillEvent(
          id: map['id'] as String,
          skillId: map['skillId'] as String? ?? '',
          amount: (map['amount'] as num?)?.toInt() ?? 0,
          source: map['source'] as String? ?? '',
          createdAt: DateTime.parse(map['createdAt'] as String),
        );
      }).toList(),
    );
  }
}
