import '../../../../core/utils/result.dart';
import '../../../quests/domain/entities/quest.dart';
import '../../domain/entities/boss.dart';
import '../../domain/repositories/boss_repository.dart';
import '../datasources/boss_remote_datasource.dart';

class BossRepositoryImpl implements BossRepository {
  const BossRepositoryImpl(this._remote);
  final BossRemoteDataSource _remote;

  @override
  Future<Result<List<Boss>>> getBosses() => guardResult(() async {
        final models = await _remote.list();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<Boss>> getBoss(String id) =>
      guardResult(() async => (await _remote.get(id)).toEntity());

  @override
  Future<Result<List<Quest>>> getLinkedQuests(String bossId) => guardResult(() async {
        final models = await _remote.linkedQuests(bossId);
        return models.map((m) => m.toEntity()).toList();
      });
}
