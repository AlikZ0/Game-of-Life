import '../../../../core/utils/result.dart';
import '../entities/quest_reward.dart';
import '../repositories/quest_repository.dart';

class CompleteQuest {
  const CompleteQuest(this._repo);
  final QuestRepository _repo;

  Future<Result<QuestReward>> call(String questId) => _repo.completeQuest(questId);
}
