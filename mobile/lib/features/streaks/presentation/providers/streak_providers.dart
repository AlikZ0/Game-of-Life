import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../data/datasources/streak_remote_datasource.dart';
import '../../data/repositories_impl/streak_repository_impl.dart';
import '../../domain/entities/streak.dart';
import '../../domain/repositories/streak_repository.dart';

final streakRemoteDataSourceProvider = Provider<StreakRemoteDataSource>(
  (ref) => StreakRemoteDataSource(ref.watch(dioProvider)),
);

final streakRepositoryProvider = Provider<StreakRepository>(
  (ref) => StreakRepositoryImpl(ref.watch(streakRemoteDataSourceProvider)),
);

/// Fetches the current streak. Kept lightweight (single endpoint) so it can be
/// watched by both the dashboard flame and the milestones screen.
final streakProvider = FutureProvider<Streak>((ref) async {
  final result = await ref.watch(streakRepositoryProvider).getStreak();
  return result.fold(onSuccess: (s) => s, onFailure: (e) => throw e);
});
