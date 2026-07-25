/// A single AI-coach suggestion. The backend derives these from the user's
/// recent activity (streaks at risk, neglected skills, boss deadlines).
class CoachSuggestion {
  const CoachSuggestion({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.actionLabel,
    this.actionRoute,
  });

  final String id;
  final String title;
  final String body;
  final String type; // motivation | warning | tip | insight
  final String? actionLabel;
  final String? actionRoute;
}
