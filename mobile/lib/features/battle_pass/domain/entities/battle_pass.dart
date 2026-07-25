/// Domain entities for the battle pass. Mirror Prisma `Season`,
/// `BattlePassTier`, and `BattlePassProgress`.
class BattlePass {
  const BattlePass({
    required this.seasonName,
    required this.endAt,
    required this.currentTier,
    required this.xp,
    required this.isPremium,
    required this.claimedTiers,
    required this.tiers,
  });

  final String seasonName;
  final DateTime endAt;
  final int currentTier;
  final int xp;
  final bool isPremium;
  final List<int> claimedTiers;
  final List<BattlePassTier> tiers;

  bool isClaimed(int tier) => claimedTiers.contains(tier);
}

class BattlePassTier {
  const BattlePassTier({
    required this.tier,
    required this.xpRequired,
    this.freeReward,
    this.premiumReward,
  });

  final int tier;
  final int xpRequired;
  final String? freeReward;
  final String? premiumReward;
}
