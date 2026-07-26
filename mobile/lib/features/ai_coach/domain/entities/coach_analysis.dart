/// The AI coach's analysis of the user's recent activity. Mirrors the backend
/// `GET /ai-coach/analyze` payload.
class CoachAnalysis {
  const CoachAnalysis({
    required this.summary,
    required this.weakAreas,
    required this.strengths,
    required this.suggestedQuests,
    this.predictedLevelIn30d,
    required this.premium,
  });

  final String summary;
  final List<String> weakAreas;
  final List<String> strengths;
  final List<SuggestedQuest> suggestedQuests;

  /// Projected character level 30 days out; null when the model can't predict.
  final int? predictedLevelIn30d;

  /// Whether the full analysis is gated behind a premium subscription.
  final bool premium;
}

/// A quest the coach recommends the user add to their routine.
class SuggestedQuest {
  const SuggestedQuest({
    required this.title,
    required this.cadence,
    required this.difficulty,
    required this.skillKey,
    required this.rationale,
  });

  final String title;
  final String cadence; // DAILY | WEEKLY | ONE_OFF
  final String difficulty; // TRIVIAL | EASY | MEDIUM | HARD | EPIC
  final String skillKey;
  final String rationale;
}
