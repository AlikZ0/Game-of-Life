import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/streak_model.dart';
import '../../domain/entities/streak.dart';

/// Fetches the current streak. Kept lightweight (single endpoint) so it can be
/// watched by both the dashboard flame and the milestones screen.
final streakProvider = FutureProvider<Streak>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.streak);
  return StreakModel.fromJson(res.data!).toEntity();
});
