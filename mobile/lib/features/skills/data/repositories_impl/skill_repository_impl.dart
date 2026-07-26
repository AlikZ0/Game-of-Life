import '../../../../core/utils/result.dart';
import '../../domain/entities/skill.dart';
import '../../domain/repositories/skill_repository.dart';
import '../datasources/skill_remote_datasource.dart';

class SkillRepositoryImpl implements SkillRepository {
  const SkillRepositoryImpl(this._remote);
  final SkillRemoteDataSource _remote;

  @override
  Future<Result<List<Skill>>> getSkills() => guardResult(() async {
        final models = await _remote.list();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<List<SkillHeatCell>>> getHeatmap({int days = 90}) =>
      guardResult(() => _remote.heatmap(days: days));

  @override
  Future<Result<SkillHistory>> getHistory(String skillKey) =>
      guardResult(() => _remote.history(skillKey));
}
