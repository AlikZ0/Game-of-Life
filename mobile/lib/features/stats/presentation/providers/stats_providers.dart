import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/stats_summary.dart';

final statsSummaryProvider = FutureProvider<StatsSummary>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.statsSummary);
  final data = res.data ?? const {};

  return StatsSummary(
    questsCompleted: (data['questsCompleted'] as num?)?.toInt() ?? 0,
    completionRate: (data['completionRate'] as num?)?.toDouble() ?? 0,
    totalXp: (data['totalXp'] as num?)?.toInt() ?? 0,
    totalGold: (data['totalGold'] as num?)?.toInt() ?? 0,
    activeDays: (data['activeDays'] as num?)?.toInt() ?? 0,
    xpSeries: [
      for (final p in (data['xpSeries'] ?? const []) as List<dynamic>)
        XpPoint(
          day: DateTime.tryParse(p['day'] as String? ?? '') ?? DateTime.now(),
          xp: (p['xp'] as num?)?.toInt() ?? 0,
        ),
    ],
  );
});
