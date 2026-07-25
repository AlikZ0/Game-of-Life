import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/achievement_model.dart';
import '../../domain/entities/achievement.dart';

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.achievements);
  final items = (res.data?['data'] ?? res.data?['achievements'] ?? const []) as List<dynamic>;
  return items
      .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>).toEntity())
      .toList();
});
