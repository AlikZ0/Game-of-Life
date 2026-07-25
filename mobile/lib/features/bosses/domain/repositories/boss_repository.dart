import '../../../../core/utils/result.dart';
import '../../../quests/domain/entities/quest.dart';
import '../entities/boss.dart';

abstract interface class BossRepository {
  Future<Result<List<Boss>>> getBosses();
  Future<Result<Boss>> getBoss(String id);
  Future<Result<List<Quest>>> getLinkedQuests(String bossId);
}
