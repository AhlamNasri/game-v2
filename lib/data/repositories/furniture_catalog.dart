import 'package:flutter/material.dart';

/// Cosmetic rarity tier — drives badge color/label across the shop.
/// Shared by clothing and furniture so the visual language is consistent.
enum ItemRarity { common, rare, epic, legendary }

extension ItemRarityStyle on ItemRarity {
  String get label {
    switch (this) {
      case ItemRarity.common:
        return 'Common';
      case ItemRarity.rare:
        return 'Rare';
      case ItemRarity.epic:
        return 'Epic';
      case ItemRarity.legendary:
        return 'Legendary';
    }
  }

  Color get color {
    switch (this) {
      case ItemRarity.common:
        return const Color(0xFF8FB7A6);
      case ItemRarity.rare:
        return const Color(0xFF5B9BD5);
      case ItemRarity.epic:
        return const Color(0xFFA97CC8);
      case ItemRarity.legendary:
        return const Color(0xFFE7A33E);
    }
  }

  /// Derives a rarity tier from a coin price so we keep one source of truth.
  static ItemRarity fromPrice(int price) {
    if (price >= 1200) return ItemRarity.legendary;
    if (price >= 900) return ItemRarity.epic;
    if (price >= 400) return ItemRarity.rare;
    return ItemRarity.common;
  }
}

enum FurnitureCategory { beds, lamps, desks, decor }

extension FurnitureCategoryStyle on FurnitureCategory {
  String get label {
    switch (this) {
      case FurnitureCategory.beds:
        return 'Beds';
      case FurnitureCategory.lamps:
        return 'Lamps';
      case FurnitureCategory.desks:
        return 'Desks';
      case FurnitureCategory.decor:
        return 'Decor';
    }
  }

  IconData get icon {
    switch (this) {
      case FurnitureCategory.beds:
        return Icons.bed_rounded;
      case FurnitureCategory.lamps:
        return Icons.light_rounded;
      case FurnitureCategory.desks:
        return Icons.desk_rounded;
      case FurnitureCategory.decor:
        return Icons.auto_awesome_rounded;
    }
  }
}

/// A purchasable room item.
///
/// [id] is the stable key persisted to `user_rooms/{uid}.inventory`. It is the
/// `room_items_shop/` file stem, which the room screen resolves back to
/// `room_items_shop/$id.png` when building the placeable inventory — so a
/// purchase is immediately placeable with no restart.
class FurnitureShopItem {
  final String id;
  final String name;
  final int price;
  final FurnitureCategory category;

  const FurnitureShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  /// All shop assets live in `room_items_shop/` (declared in pubspec.yaml).
  String get asset => 'room_items_shop/$id.png';

  ItemRarity get rarity => ItemRarityStyle.fromPrice(price);
}

class FurnitureCatalog {
  const FurnitureCatalog._();

  /// Single source of truth for the furniture shop. IDs match the
  /// `room_items_shop/` filenames so the room inventory resolves them directly.
  static const List<FurnitureShopItem> items = [
    // ── Beds & seating ──
    FurnitureShopItem(
        id: 'bed3', name: 'Heart Bed', price: 800,
        category: FurnitureCategory.beds),
    FurnitureShopItem(
        id: 'sofa', name: 'Cozy Sofa', price: 1000,
        category: FurnitureCategory.beds),
    FurnitureShopItem(
        id: 'sofa2', name: 'Lounge Sofa', price: 1300,
        category: FurnitureCategory.beds),
    FurnitureShopItem(
        id: 'heartchair', name: 'Heart Chair', price: 1200,
        category: FurnitureCategory.beds),
    FurnitureShopItem(
        id: 'chair', name: 'Comfy Chair', price: 450,
        category: FurnitureCategory.beds),
    FurnitureShopItem(
        id: 'pinkChair-removebg-preview', name: 'Pink Chair', price: 550,
        category: FurnitureCategory.beds),
    // ── Lamps ──
    FurnitureShopItem(
        id: 'chandelier', name: 'Chandelier', price: 350,
        category: FurnitureCategory.lamps),
    FurnitureShopItem(
        id: 'lamp', name: 'Star Lamp', price: 450,
        category: FurnitureCategory.lamps),
    FurnitureShopItem(
        id: 'greendeco', name: 'Green Deco', price: 400,
        category: FurnitureCategory.lamps),
    // ── Desks ──
    FurnitureShopItem(
        id: 'desk', name: 'Desk', price: 900,
        category: FurnitureCategory.desks),
    FurnitureShopItem(
        id: 'fire', name: 'Fireplace', price: 1500,
        category: FurnitureCategory.desks),
    FurnitureShopItem(
        id: 'piano', name: 'Piano', price: 1100,
        category: FurnitureCategory.desks),
    FurnitureShopItem(
        id: 'book_shelf', name: 'Book Shelf', price: 350,
        category: FurnitureCategory.desks),
    // ── Decor ──
    FurnitureShopItem(
        id: 'bath', name: 'Bathtub', price: 300,
        category: FurnitureCategory.decor),
    FurnitureShopItem(
        id: 'cam', name: 'Camera', price: 350,
        category: FurnitureCategory.decor),
    FurnitureShopItem(
        id: 'clock', name: 'Clock', price: 420,
        category: FurnitureCategory.decor),
    FurnitureShopItem(
        id: 'curtain', name: 'Curtains', price: 300,
        category: FurnitureCategory.decor),
    FurnitureShopItem(
        id: 'mirroir', name: 'Mirror', price: 450,
        category: FurnitureCategory.decor),
    FurnitureShopItem(
        id: 'fridge', name: 'Fridge', price: 1000,
        category: FurnitureCategory.decor),
    FurnitureShopItem(
        id: 'pc', name: 'PC', price: 1500,
        category: FurnitureCategory.decor),
    FurnitureShopItem(
        id: 'sink', name: 'Sink', price: 500,
        category: FurnitureCategory.decor),
  ];

  /// Catalog grouped by category in declaration order — used by the shop to
  /// render one section per [FurnitureCategory] with zero hardcoded lists.
  static Map<FurnitureCategory, List<FurnitureShopItem>> get byCategory {
    final map = <FurnitureCategory, List<FurnitureShopItem>>{
      for (final c in FurnitureCategory.values) c: <FurnitureShopItem>[],
    };
    for (final item in items) {
      map[item.category]!.add(item);
    }
    return map;
  }
}
