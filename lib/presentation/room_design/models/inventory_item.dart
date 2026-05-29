class InventoryItem {
  final String id;
  final String name;
  final String asset;
  final bool fromShop;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.asset,
    this.fromShop = false,
  });
}
