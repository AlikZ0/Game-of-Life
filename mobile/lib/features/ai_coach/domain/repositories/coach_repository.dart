import '../../../../core/utils/result.dart';
import '../entities/coach_analysis.dart';

abstract interface class CoachRepository {
  Future<Result<CoachAnalysis>> getAnalysis();
}
