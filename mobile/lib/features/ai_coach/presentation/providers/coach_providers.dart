import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../data/datasources/coach_remote_datasource.dart';
import '../../data/repositories_impl/coach_repository_impl.dart';
import '../../domain/entities/coach_analysis.dart';
import '../../domain/repositories/coach_repository.dart';

final coachRemoteDataSourceProvider = Provider<CoachRemoteDataSource>(
  (ref) => CoachRemoteDataSource(ref.watch(dioProvider)),
);

final coachRepositoryProvider = Provider<CoachRepository>(
  (ref) => CoachRepositoryImpl(ref.watch(coachRemoteDataSourceProvider)),
);

final coachAnalysisProvider = FutureProvider<CoachAnalysis>((ref) async {
  final result = await ref.watch(coachRepositoryProvider).getAnalysis();
  return result.fold(onSuccess: (a) => a, onFailure: (e) => throw e);
});
