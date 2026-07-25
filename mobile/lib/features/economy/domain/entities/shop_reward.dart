/// Domain entity for a user-defined real-life reward purchasable with gold.
/// Mirrors Prisma `ShopReward`.
class ShopReward {
  const ShopReward({
    required this.id,
    required this.title,
    this.description,
    required this.icon,
    required this.goldCost,
    this.stock,
    required this.timesRedeemed,
    required this.isActive,
  });

  final String id;
  final String title;
  final String? description;
  final String icon;
  final int goldCost;
  final int? stock; // null = unlimited
  final int timesRedeemed;
  final bool isActive;

  bool get isSoldOut => stock != null && stock! <= 0;
}
