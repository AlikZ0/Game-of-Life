import '../../../../core/utils/result.dart';
import '../../domain/entities/streak.dart';
import '../../domain/repositories/streak_repository.dart';
import '../datasources/streak_remote_datasource.dart';

class StreakRepositoryImpl implements StreakRepository {
  const StreakRepositoryImpl(this._remote);
  final StreakRemoteDataSource _remote;

  @override
  Future<Result<Streak>> getStreak() =>
      guardResult(() async => (await _remote.me()).toEntity());
}
