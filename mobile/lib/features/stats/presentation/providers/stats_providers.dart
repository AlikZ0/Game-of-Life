import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../data/datasources/stats_remote_datasource.dart';
import '../../data/repositories_impl/stats_repository_impl.dart';
import '../../domain/entities/life_balance.dart';
import '../../domain/entities/stats_dashboard.dart';
import '../../domain/entities/xp_point.dart';
import '../../domain/repositories/stats_repository.dart';

final statsRemoteDataSourceProvider = Provider<StatsRemoteDataSource>(
  (ref) => StatsRemoteDataSource(ref.watch(dioProvider)),
);

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => StatsRepositoryImpl(ref.watch(statsRemoteDataSourceProvider)),
);

final statsDashboardProvider = FutureProvider<StatsDashboard>((ref) async {
  final result = await ref.watch(statsRepositoryProvider).getDashboard();
  return result.fold(onSuccess: (d) => d, onFailure: (e) => throw e);
});

final statsXpSeriesProvider = FutureProvider<List<XpPoint>>((ref) async {
  final result = await ref.watch(statsRepositoryProvider).getXpSeries(days: 30);
  return result.fold(onSuccess: (s) => s, onFailure: (e) => throw e);
});

final statsLifeBalanceProvider = FutureProvider<List<LifeBalanceSlice>>((ref) async {
  final result = await ref.watch(statsRepositoryProvider).getLifeBalance();
  return result.fold(onSuccess: (b) => b, onFailure: (e) => throw e);
});
