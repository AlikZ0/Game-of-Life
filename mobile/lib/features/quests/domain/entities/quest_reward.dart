/// The reward payload returned by `POST /quests/:id/complete`. Drives the
/// celebratory reward animation on the dashboard.
class QuestReward {
  const QuestReward({
    required this.xpAwarded,
    required this.goldAwarded,
    required this.leveledUp,
    required this.newLevel,
    this.skillKey,
    this.skillXp = 0,
    this.bossDamage = 0,
    this.bossDefeated = false,
    this.streakCount = 0,
  });

  final int xpAwarded;
  final int goldAwarded;
  final bool leveledUp;
  final int newLevel;
  final String? skillKey;
  final int skillXp;
  final int bossDamage;
  final bool bossDefeated;
  final int streakCount;
}
