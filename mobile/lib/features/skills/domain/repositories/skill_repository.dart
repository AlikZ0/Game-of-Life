import '../../../../core/utils/result.dart';
import '../entities/skill.dart';

abstract interface class SkillRepository {
  Future<Result<List<Skill>>> getSkills();
  Future<Result<List<SkillHeatCell>>> getHeatmap({int days});
  Future<Result<SkillHistory>> getHistory(String skillKey);
}
