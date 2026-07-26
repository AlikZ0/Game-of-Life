import '../../../../core/utils/result.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/shop_reward.dart';
import '../../domain/repositories/economy_repository.dart';
import '../datasources/economy_remote_datasource.dart';

class EconomyRepositoryImpl implements EconomyRepository {
  const EconomyRepositoryImpl(this._remote);
  final EconomyRemoteDataSource _remote;

  @override
  Future<Result<List<InventoryItem>>> getInventory() => guardResult(() async {
        final models = await _remote.inventory();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<List<ShopReward>>> getShopRewards() => guardResult(() async {
        final models = await _remote.shop();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<int>> redeemReward(String rewardId) =>
      guardResult(() => _remote.redeem(rewardId));
}
