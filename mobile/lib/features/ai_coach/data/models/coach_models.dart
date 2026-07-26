import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/coach_analysis.dart';

part 'coach_models.freezed.dart';
part 'coach_models.g.dart';

@freezed
class CoachAnalysisModel with _$CoachAnalysisModel {
  const CoachAnalysisModel._();

  const factory CoachAnalysisModel({
    @Default('') String summary,
    @JsonKey(name: 'weakAreas') @Default(<String>[]) List<String> weakAreas,
    @Default(<String>[]) List<String> strengths,
    @JsonKey(name: 'suggestedQuests') @Default(<SuggestedQuestModel>[]) List<SuggestedQuestModel> suggestedQuests,
    @JsonKey(name: 'predictedLevelIn30d') int? predictedLevelIn30d,
    @Default(false) bool premium,
  }) = _CoachAnalysisModel;

  factory CoachAnalysisModel.fromJson(Map<String, dynamic> json) =>
      _$CoachAnalysisModelFromJson(json);

  CoachAnalysis toEntity() => CoachAnalysis(
        summary: summary,
        weakAreas: weakAreas,
        strengths: strengths,
        suggestedQuests: suggestedQuests.map((q) => q.toEntity()).toList(),
        predictedLevelIn30d: predictedLevelIn30d,
        premium: premium,
      );
}

@freezed
class SuggestedQuestModel with _$SuggestedQuestModel {
  const SuggestedQuestModel._();

  const factory SuggestedQuestModel({
    @Default('') String title,
    @Default('DAILY') String cadence,
    @Default('MEDIUM') String difficulty,
    @JsonKey(name: 'skillKey') @Default('') String skillKey,
    @Default('') String rationale,
  }) = _SuggestedQuestModel;

  factory SuggestedQuestModel.fromJson(Map<String, dynamic> json) =>
      _$SuggestedQuestModelFromJson(json);

  SuggestedQuest toEntity() => SuggestedQuest(
        title: title,
        cadence: cadence,
        difficulty: difficulty,
        skillKey: skillKey,
        rationale: rationale,
      );
}
