import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../quests/data/models/quest_model.dart';
import '../models/boss_model.dart';

class BossRemoteDataSource {
  const BossRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<BossModel>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.bosses);
    final items = (res.data?['data'] ?? res.data?['bosses'] ?? const []) as List<dynamic>;
    return items.map((e) => BossModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BossModel> get(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.boss(id));
    return BossModel.fromJson((res.data?['data'] ?? res.data) as Map<String, dynamic>);
  }

  /// Quests linked to a boss (each deals damage on completion).
  Future<List<QuestModel>> linkedQuests(String bossId) async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.bossQuests(bossId));
    final items = (res.data?['data'] ?? res.data?['quests'] ?? const []) as List<dynamic>;
    return items.map((e) => QuestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BossModel> create(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.bosses, data: body);
    return BossModel.fromJson((res.data?['data'] ?? res.data) as Map<String, dynamic>);
  }
}
