/// Aggregated insight metrics for the statistics dashboard.
class StatsSummary {
  const StatsSummary({
    required this.questsCompleted,
    required this.completionRate,
    required this.totalXp,
    required this.totalGold,
    required this.activeDays,
    required this.xpSeries,
  });

  final int questsCompleted;

  /// 0..1 completion rate over the tracked window.
  final double completionRate;
  final int totalXp;
  final int totalGold;
  final int activeDays;

  /// Daily XP points for the line chart (oldest → newest).
  final List<XpPoint> xpSeries;
}

class XpPoint {
  const XpPoint({required this.day, required this.xp});
  final DateTime day;
  final int xp;
}
