import '../../../../core/utils/result.dart';
import '../../domain/entities/battle_pass.dart';
import '../../domain/repositories/battle_pass_repository.dart';
import '../datasources/battle_pass_remote_datasource.dart';

class BattlePassRepositoryImpl implements BattlePassRepository {
  const BattlePassRepositoryImpl(this._remote);
  final BattlePassRemoteDataSource _remote;

  @override
  Future<Result<BattlePass>> getCurrent() =>
      guardResult(() async => (await _remote.current()).toEntity());

  @override
  Future<Result<void>> claimTier(int tier) =>
      guardResult(() => _remote.claim(tier));
}
