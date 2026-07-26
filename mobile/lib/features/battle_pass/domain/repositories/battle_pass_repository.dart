import '../../../../core/utils/result.dart';
import '../entities/battle_pass.dart';

abstract interface class BattlePassRepository {
  Future<Result<BattlePass>> getCurrent();
  Future<Result<void>> claimTier(int tier);
}
