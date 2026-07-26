import '../../../../core/utils/result.dart';
import '../entities/life_balance.dart';
import '../entities/stats_dashboard.dart';
import '../entities/xp_point.dart';

abstract interface class StatsRepository {
  Future<Result<StatsDashboard>> getDashboard();
  Future<Result<List<XpPoint>>> getXpSeries({int days});
  Future<Result<List<LifeBalanceSlice>>> getLifeBalance();
}
