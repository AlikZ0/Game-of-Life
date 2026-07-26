import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../data/datasources/battle_pass_remote_datasource.dart';
import '../../data/repositories_impl/battle_pass_repository_impl.dart';
import '../../domain/entities/battle_pass.dart';
import '../../domain/repositories/battle_pass_repository.dart';

final battlePassRemoteDataSourceProvider = Provider<BattlePassRemoteDataSource>(
  (ref) => BattlePassRemoteDataSource(ref.watch(dioProvider)),
);

final battlePassRepositoryProvider = Provider<BattlePassRepository>(
  (ref) => BattlePassRepositoryImpl(ref.watch(battlePassRemoteDataSourceProvider)),
);

final battlePassProvider = FutureProvider<BattlePass>((ref) async {
  final result = await ref.watch(battlePassRepositoryProvider).getCurrent();
  return result.fold(onSuccess: (p) => p, onFailure: (e) => throw e);
});
