import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/quest.dart';
import '../models/quest_model.dart';
import '../models/quest_reward_model.dart';

class QuestRemoteDataSource {
  const QuestRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<QuestModel>> list({String? cadence}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.quests,
      queryParameters: {if (cadence != null) 'cadence': cadence},
    );
    final items = (res.data?['data'] ?? res.data?['quests'] ?? const []) as List<dynamic>;
    return items
        .map((e) => QuestModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<QuestModel> create(QuestDraft draft) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.quests,
      data: draft.toJson(),
    );
    return QuestModel.fromJson(res.data!);
  }

  Future<QuestModel> update(QuestDraft draft) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.quest(draft.id!),
      data: draft.toJson(),
    );
    return QuestModel.fromJson(res.data!);
  }

  Future<void> archive(String id) => _dio.delete<void>(ApiEndpoints.quest(id));

  Future<QuestRewardModel> complete(String id) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.completeQuest(id));
    return QuestRewardModel.fromJson(res.data!);
  }
}
