import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../../quests/domain/entities/quest.dart';
import '../../data/datasources/boss_remote_datasource.dart';
import '../../data/repositories_impl/boss_repository_impl.dart';
import '../../domain/entities/boss.dart';
import '../../domain/repositories/boss_repository.dart';

final bossRemoteDataSourceProvider = Provider<BossRemoteDataSource>(
  (ref) => BossRemoteDataSource(ref.watch(dioProvider)),
);

final bossRepositoryProvider = Provider<BossRepository>(
  (ref) => BossRepositoryImpl(ref.watch(bossRemoteDataSourceProvider)),
);

final bossesProvider = FutureProvider<List<Boss>>((ref) async {
  final result = await ref.watch(bossRepositoryProvider).getBosses();
  return result.fold(onSuccess: (b) => b, onFailure: (e) => throw e);
});

final bossDetailProvider = FutureProvider.family<Boss, String>((ref, id) async {
  final result = await ref.watch(bossRepositoryProvider).getBoss(id);
  return result.fold(onSuccess: (b) => b, onFailure: (e) => throw e);
});

final bossQuestsProvider = FutureProvider.family<List<Quest>, String>((ref, bossId) async {
  final result = await ref.watch(bossRepositoryProvider).getLinkedQuests(bossId);
  return result.fold(onSuccess: (q) => q, onFailure: (e) => throw e);
});
