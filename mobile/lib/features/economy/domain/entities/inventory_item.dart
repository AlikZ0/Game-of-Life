/// Domain entity for an owned item. Mirrors Prisma `InventoryItem`.
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.itemType,
    required this.refKey,
    required this.name,
    required this.quantity,
    required this.equipped,
  });

  final String id;
  final String itemType; // COSMETIC_* | TITLE | REWARD_COUPON | CONSUMABLE_*
  final String refKey;
  final String name;
  final int quantity;
  final bool equipped;

  bool get isCosmetic => itemType.startsWith('COSMETIC');
  bool get isConsumable => itemType.startsWith('CONSUMABLE');
}
