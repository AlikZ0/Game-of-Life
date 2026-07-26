import '../../../../core/utils/result.dart';
import '../entities/streak.dart';

abstract interface class StreakRepository {
  Future<Result<Streak>> getStreak();
}
