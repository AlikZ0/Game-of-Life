import '../../../../core/utils/result.dart';
import '../../domain/entities/quest.dart';
import '../../domain/entities/quest_reward.dart';
import '../../domain/repositories/quest_repository.dart';
import '../datasources/quest_remote_datasource.dart';

class QuestRepositoryImpl implements QuestRepository {
  const QuestRepositoryImpl(this._remote);
  final QuestRemoteDataSource _remote;

  @override
  Future<Result<List<Quest>>> getQuests({String? cadence}) => guardResult(() async {
        final models = await _remote.list(cadence: cadence);
        return models.map((m) => m.toEntity()).toList(growable: false);
      });

  @override
  Future<Result<Quest>> createQuest(QuestDraft draft) =>
      guardResult(() async => (await _remote.create(draft)).toEntity());

  @override
  Future<Result<Quest>> updateQuest(QuestDraft draft) =>
      guardResult(() async => (await _remote.update(draft)).toEntity());

  @override
  Future<Result<void>> archiveQuest(String id) =>
      guardResult(() => _remote.archive(id));

  @override
  Future<Result<QuestReward>> completeQuest(String id) =>
      guardResult(() async => (await _remote.complete(id)).toEntity());
}
