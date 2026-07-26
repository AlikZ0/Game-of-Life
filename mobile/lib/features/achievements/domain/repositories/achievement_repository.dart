import '../../../../core/utils/result.dart';
import '../entities/achievement.dart';

abstract interface class AchievementRepository {
  Future<Result<List<Achievement>>> getAchievements();
}
