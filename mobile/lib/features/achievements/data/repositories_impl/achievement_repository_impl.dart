import '../../../../core/utils/result.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../datasources/achievement_remote_datasource.dart';

class AchievementRepositoryImpl implements AchievementRepository {
  const AchievementRepositoryImpl(this._remote);
  final AchievementRemoteDataSource _remote;

  @override
  Future<Result<List<Achievement>>> getAchievements() => guardResult(() async {
        final models = await _remote.list();
        return models.map((m) => m.toEntity()).toList();
      });
}
