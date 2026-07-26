import '../../../../core/utils/result.dart';
import '../../domain/entities/life_balance.dart';
import '../../domain/entities/stats_dashboard.dart';
import '../../domain/entities/xp_point.dart';
import '../../domain/repositories/stats_repository.dart';
import '../datasources/stats_remote_datasource.dart';

class StatsRepositoryImpl implements StatsRepository {
  const StatsRepositoryImpl(this._remote);
  final StatsRemoteDataSource _remote;

  @override
  Future<Result<StatsDashboard>> getDashboard() =>
      guardResult(() async => (await _remote.dashboard()).toEntity());

  @override
  Future<Result<List<XpPoint>>> getXpSeries({int days = 30}) =>
      guardResult(() => _remote.xpSeries(days: days));

  @override
  Future<Result<List<LifeBalanceSlice>>> getLifeBalance() =>
      guardResult(() => _remote.lifeBalance());
}
