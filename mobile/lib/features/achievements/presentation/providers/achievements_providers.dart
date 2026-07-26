import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../data/datasources/achievement_remote_datasource.dart';
import '../../data/repositories_impl/achievement_repository_impl.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/repositories/achievement_repository.dart';

final achievementRemoteDataSourceProvider = Provider<AchievementRemoteDataSource>(
  (ref) => AchievementRemoteDataSource(ref.watch(dioProvider)),
);

final achievementRepositoryProvider = Provider<AchievementRepository>(
  (ref) => AchievementRepositoryImpl(ref.watch(achievementRemoteDataSourceProvider)),
);

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final result = await ref.watch(achievementRepositoryProvider).getAchievements();
  return result.fold(onSuccess: (a) => a, onFailure: (e) => throw e);
});
