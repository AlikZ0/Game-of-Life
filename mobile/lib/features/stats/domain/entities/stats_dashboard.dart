/// Headline insight metrics for the statistics dashboard. Mirrors the backend
/// `GET /stats/dashboard` payload.
class StatsDashboard {
  const StatsDashboard({
    required this.level,
    required this.totalXp,
    required this.gold,
    required this.questsCompleted30d,
    required this.activeQuests,
    required this.currentStreak,
    required this.longestStreak,
    required this.skillBalance,
  });

  final int level;
  final int totalXp;
  final int gold;
  final int questsCompleted30d;
  final int activeQuests;
  final int currentStreak;
  final int longestStreak;
  final List<SkillBalance> skillBalance;
}

/// A per-skill XP snapshot used to render the skill-balance breakdown.
class SkillBalance {
  const SkillBalance({
    required this.key,
    required this.name,
    required this.level,
    required this.totalXp,
  });

  final String key;
  final String name;
  final int level;
  final int totalXp;
}
