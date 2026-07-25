/// Domain entity for a Boss (a big goal rendered as an HP bar). Mirrors Prisma
/// `Boss`.
class Boss {
  const Boss({
    required this.id,
    required this.name,
    this.description,
    required this.imageKey,
    required this.maxHp,
    required this.currentHp,
    required this.status,
    required this.rewardXp,
    required this.rewardGold,
    this.deadline,
  });

  final String id;
  final String name;
  final String? description;
  final String imageKey;
  final int maxHp;
  final int currentHp;
  final String status; // ACTIVE | DEFEATED | ABANDONED
  final int rewardXp;
  final int rewardGold;
  final DateTime? deadline;

  bool get isDefeated => status == 'DEFEATED' || currentHp <= 0;

  /// Remaining HP as a fraction, 0..1.
  double get hpFraction => maxHp == 0 ? 0 : (currentHp / maxHp).clamp(0.0, 1.0);

  /// How much damage has been dealt, 0..1 (for progress framing).
  double get progress => 1 - hpFraction;

  int get damageDealt => (maxHp - currentHp).clamp(0, maxHp);
}
