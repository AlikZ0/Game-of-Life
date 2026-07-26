/// A single day's XP total for the XP-over-time line chart.
class XpPoint {
  const XpPoint({required this.day, required this.xp});
  final DateTime day;
  final int xp;
}
