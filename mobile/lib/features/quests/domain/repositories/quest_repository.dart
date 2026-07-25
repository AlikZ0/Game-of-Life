import '../../../../core/utils/result.dart';
import '../entities/quest.dart';
import '../entities/quest_reward.dart';

abstract interface class QuestRepository {
  /// Lists the active quests, optionally filtered by cadence.
  Future<Result<List<Quest>>> getQuests({String? cadence});

  Future<Result<Quest>> createQuest(QuestDraft draft);

  Future<Result<Quest>> updateQuest(QuestDraft draft);

  Future<Result<void>> archiveQuest(String id);

  /// Completes a quest for the current period; returns the awarded rewards.
  Future<Result<QuestReward>> completeQuest(String id);
}
