import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../data/datasources/skill_remote_datasource.dart';
import '../../data/repositories_impl/skill_repository_impl.dart';
import '../../domain/entities/skill.dart';
import '../../domain/repositories/skill_repository.dart';

final skillRemoteDataSourceProvider = Provider<SkillRemoteDataSource>(
  (ref) => SkillRemoteDataSource(ref.watch(dioProvider)),
);

final skillRepositoryProvider = Provider<SkillRepository>(
  (ref) => SkillRepositoryImpl(ref.watch(skillRemoteDataSourceProvider)),
);

final skillsProvider = FutureProvider<List<Skill>>((ref) async {
  final result = await ref.watch(skillRepositoryProvider).getSkills();
  return result.fold(onSuccess: (s) => s, onFailure: (e) => throw e);
});

/// Aggregated activity heatmap across all skills for the last ~90 days,
/// sourced from the dedicated `/skills/heatmap` endpoint.
final skillHeatmapProvider = FutureProvider<List<SkillHeatCell>>((ref) async {
  final result = await ref.watch(skillRepositoryProvider).getHeatmap();
  return result.fold(onSuccess: (h) => h, onFailure: (_) => const []);
});

/// A single skill's XP-event history, keyed by the skill's KEY.
final skillHistoryProvider =
    FutureProvider.family<SkillHistory, String>((ref, skillKey) async {
  final result = await ref.watch(skillRepositoryProvider).getHistory(skillKey);
  return result.fold(onSuccess: (h) => h, onFailure: (e) => throw e);
});
