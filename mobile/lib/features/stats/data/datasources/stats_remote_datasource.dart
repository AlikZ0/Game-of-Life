import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/life_balance.dart';
import '../../domain/entities/xp_point.dart';
import '../models/stats_models.dart';

class StatsRemoteDataSource {
  const StatsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<StatsDashboardModel> dashboard() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.statsDashboard);
    final data = (res.data?['data'] ?? res.data ?? const {}) as Map<String, dynamic>;
    return StatsDashboardModel.fromJson(data);
  }

  Future<List<XpPoint>> xpSeries({int days = 30}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.statsXpSeries,
      queryParameters: {'days': days},
    );
    final items = (res.data?['data'] ?? const []) as List<dynamic>;
    return items.map((e) {
      final map = e as Map<String, dynamic>;
      return XpPoint(
        day: DateTime.parse(map['date'] as String),
        xp: (map['xp'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<List<LifeBalanceSlice>> lifeBalance() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.statsLifeBalance);
    final items = (res.data?['data'] ?? const []) as List<dynamic>;
    return items.map((e) {
      final map = e as Map<String, dynamic>;
      return LifeBalanceSlice(
        key: map['key'] as String? ?? '',
        name: map['name'] as String? ?? '',
        share: (map['share'] as num?)?.toDouble() ?? 0,
        neglected: map['neglected'] as bool? ?? false,
      );
    }).toList();
  }
}
