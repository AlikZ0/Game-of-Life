import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../../character/presentation/providers/character_providers.dart';
import '../../data/datasources/economy_remote_datasource.dart';
import '../../data/repositories_impl/economy_repository_impl.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/shop_reward.dart';
import '../../domain/repositories/economy_repository.dart';

final economyRemoteDataSourceProvider = Provider<EconomyRemoteDataSource>(
  (ref) => EconomyRemoteDataSource(ref.watch(dioProvider)),
);

final economyRepositoryProvider = Provider<EconomyRepository>(
  (ref) => EconomyRepositoryImpl(ref.watch(economyRemoteDataSourceProvider)),
);

final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final result = await ref.watch(economyRepositoryProvider).getInventory();
  return result.fold(onSuccess: (i) => i, onFailure: (e) => throw e);
});

final shopRewardsProvider = FutureProvider<List<ShopReward>>((ref) async {
  final result = await ref.watch(economyRepositoryProvider).getShopRewards();
  return result.fold(onSuccess: (r) => r, onFailure: (e) => throw e);
});

/// Redeems a shop reward (spends gold). Refreshes the character header + list.
final redeemRewardProvider = Provider((ref) => _RedeemReward(ref));

class _RedeemReward {
  const _RedeemReward(this._ref);
  final Ref _ref;

  Future<void> call(String rewardId) async {
    final result = await _ref.read(economyRepositoryProvider).redeemReward(rewardId);
    result.fold(
      onSuccess: (_) {
        _ref.invalidate(shopRewardsProvider);
        _ref.invalidate(myCharacterProvider);
      },
      onFailure: (e) => throw e,
    );
  }
}
