import '../../../../core/utils/result.dart';
import '../entities/inventory_item.dart';
import '../entities/shop_reward.dart';

abstract interface class EconomyRepository {
  Future<Result<List<InventoryItem>>> getInventory();
  Future<Result<List<ShopReward>>> getShopRewards();

  /// Redeems a reward; resolves with the new gold balance.
  Future<Result<int>> redeemReward(String rewardId);
}
