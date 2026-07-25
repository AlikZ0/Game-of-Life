/// Domain entity for the player's daily streak. Mirrors Prisma `Streak`.
class Streak {
  const Streak({
    required this.current,
    required this.longest,
    required this.freezeCount,
    this.lastActiveDay,
  });

  final int current;
  final int longest;
  final int freezeCount;
  final String? lastActiveDay; // YYYY-MM-DD

  static const milestones = [3, 7, 14, 30, 60, 100, 365];

  /// The next milestone the user is working toward.
  int get nextMilestone =>
      milestones.firstWhere((m) => m > current, orElse: () => current);

  /// Progress toward [nextMilestone], 0..1.
  double get milestoneProgress {
    final prev = milestones.lastWhere((m) => m <= current, orElse: () => 0);
    final span = nextMilestone - prev;
    if (span <= 0) return 1;
    return ((current - prev) / span).clamp(0.0, 1.0);
  }

  static const empty = Streak(current: 0, longest: 0, freezeCount: 0);
}
