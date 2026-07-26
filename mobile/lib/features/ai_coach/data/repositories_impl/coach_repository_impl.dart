import '../../../../core/utils/result.dart';
import '../../domain/entities/coach_analysis.dart';
import '../../domain/repositories/coach_repository.dart';
import '../datasources/coach_remote_datasource.dart';

class CoachRepositoryImpl implements CoachRepository {
  const CoachRepositoryImpl(this._remote);
  final CoachRemoteDataSource _remote;

  @override
  Future<Result<CoachAnalysis>> getAnalysis() =>
      guardResult(() async => (await _remote.analyze()).toEntity());
}
