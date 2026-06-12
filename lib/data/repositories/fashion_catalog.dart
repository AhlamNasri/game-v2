import '../models/clothing_item.dart';

/// A non-clothing customization choice (skin tone, hair style) shown during
/// character creation.
class CharacterOption {
  final String label;
  final String value;
  final String assetPath;
  final String gender;

  const CharacterOption({
    required this.label,
    required this.value,
    required this.assetPath,
    this.gender = 'all',
  });
}

/// Single source of truth for every wearable + creation option in the game.
///
/// Item IDs are stable on purpose: they are persisted in `users/{uid}
/// .boughtItems`, referenced by the shop (`clothingItemId`) and stored in
/// `outfitIds` on submitted competition outfits. Never rename an existing id.
class FashionCatalog {
  // ── LayerSpec constants for flat-lay images (no pre-fitted canvas) ─────────

  /// Full outfit (hoodie+skirt, dress, uniform) — covers shoulder → hem.
  /// Images are 165×113 landscape; widthFactor 1.15 lets BoxFit.contain
  /// scale to ~299×205 px, placing shoulders at ~26% and hem at ~76%.
  static const _outfitLayer = LayerSpec(
    centerX: 0.5,
    widthFactor: 1.15,
    heightFactor: 0.65,
    topFactor: 0.26,
  );

  /// Skirt-only bottom (same 165×113 landscape images) — sits at waist.
  static const _skirtLayer = LayerSpec(
    centerX: 0.5,
    widthFactor: 1.00,
    heightFactor: 0.52,
    topFactor: 0.43,
  );

  /// Trousers / pants — waist to ankle.
  static const _pantsLayer = LayerSpec(
    centerX: 0.5,
    widthFactor: 0.56,
    heightFactor: 0.50,
    topFactor: 0.48,
  );

  /// Top / jacket — shoulders to waist.
  static const _topLayer = LayerSpec(
    centerX: 0.5,
    widthFactor: 0.66,
    heightFactor: 0.34,
    topFactor: 0.26,
  );

  /// Shoes (front-view flat-lay) — sits at the base of the character.
  static const _shoesLayer = LayerSpec(
    centerX: 0.5,
    widthFactor: 0.54,
    heightFactor: 0.20,
    topFactor: 0.79,
  );

  /// Headphones sit on the head, not the body.
  static const _headphonesLayer = LayerSpec(
    centerX: 0.5,
    widthFactor: 0.62,
    heightFactor: 0.44,
    topFactor: 0.015,
  );

  // ── Starter pack ───────────────────────────────────────────────────────────

  /// Items every player owns from the start — always visible in the closet.
  static const starterPack = {
    // Outfits — skirts only; full dresses are in the shop
    'plaid_skirt',
    'skirt_long',
    // Tops
    'top_pink_hoodie',
    'oversized_sweater',
    // Bottoms
    'bottom_blue_jeans',
    // Shoes
    'sneakers_white',
    // Accessories — cat ears only; glasses are in the shop
    'acc_cat_ears_headband',
    // Hair
    'girl_hair1',
    'girl_hair2',
    'boy_hair1',
    'boy_hair2',
  };

  // ── Character-creation options ─────────────────────────────────────────────

  static const skinTones = [
    CharacterOption(
      label: 'Light',
      value: 'light',
      assetPath: 'assets/characters/body/girl_light_fit.png',
    ),
    CharacterOption(
      label: 'Tan',
      value: 'tan',
      assetPath: 'assets/characters/body/girl_tan.png',
    ),
  ];

  static const hairOptions = [
    CharacterOption(
      label: 'Style 1',
      value: 'hair1',
      assetPath: 'assets/characters/hair/girl_tan_head_hair1_hair_only.png',
      gender: 'girl',
    ),
    CharacterOption(
      label: 'Style 2',
      value: 'hair2',
      assetPath: 'assets/characters/hair/girl_light_head_hair2_hair_only.png',
      gender: 'girl',
    ),
    CharacterOption(
      label: 'Style 1',
      value: 'hair1',
      assetPath: 'assets/characters/hair/boy_light_head_hair1_hair_only.png',
      gender: 'boy',
    ),
    CharacterOption(
      label: 'Style 2',
      value: 'hair2',
      assetPath: 'assets/characters/hair/boy_light_head_hair2_hair_only.png',
      gender: 'boy',
    ),
  ];

  static const faceOptions = <CharacterOption>[];

  // ── Wearable catalogue ─────────────────────────────────────────────────────

  static const clothingItems = [
    // ── Outfits / dresses ────────────────────────────────────────────────────

    ClothingItem(
      id: 'casual_hoodie_skirt',
      name: 'Casual Hoodie',
      category: ClothingCategory.dresses,
      assetPath: 'assets/characters/clothes/dresses/casual.png',
      thumbPath: 'assets/characters/clothes/dresses/casual.png',
      gender: 'girl',
      layer: _outfitLayer,
    ),
    ClothingItem(
      id: 'gothic_dress',
      name: 'Gothic Dress',
      category: ClothingCategory.dresses,
      assetPath: 'assets/characters/clothes/dresses/dress.png',
      thumbPath: 'assets/characters/clothes/dresses/dress.png',
      gender: 'girl',
      layer: _outfitLayer,
    ),
    ClothingItem(
      id: 'school_uniform_new',
      name: 'School Uniform',
      category: ClothingCategory.dresses,
      assetPath: 'assets/characters/clothes/dresses/school.png',
      thumbPath: 'assets/characters/clothes/dresses/school.png',
      gender: 'girl',
      layer: _outfitLayer,
    ),
    // plaid_skirt: use _fit as both thumbnail and body layer (thumbnail PNG has green BG)
    ClothingItem(
      id: 'plaid_skirt',
      name: 'Plaid Skirt',
      category: ClothingCategory.dresses,
      assetPath: 'assets/characters/clothes/dresses/plaid_skirt_fit.png',
      thumbPath: 'assets/characters/clothes/dresses/plaid_skirt_fit.png',
      gender: 'girl',
    ),
    // Long skirt — treated as a skirt (can pair with a separate top)
    ClothingItem(
      id: 'skirt_long',
      name: 'Long Skirt',
      category: ClothingCategory.dresses,
      assetPath: 'assets/characters/clothes/dresses/skirt_long.png',
      thumbPath: 'assets/characters/clothes/dresses/skirt_long.png',
      gender: 'girl',
      layer: _skirtLayer,
    ),

    // ── Tops / shirts ────────────────────────────────────────────────────────

    ClothingItem(
      id: 'field_jacket',
      name: 'Field Jacket',
      category: ClothingCategory.shirts,
      assetPath: 'assets/characters/clothes/shirts/field_jacket.png',
      thumbPath: 'assets/characters/clothes/shirts/field_jacket.png',
      gender: 'all',
      layer: _topLayer,
    ),
    ClothingItem(
      id: 'jacket_leather_black',
      name: 'Leather Jacket',
      category: ClothingCategory.shirts,
      assetPath: 'assets/characters/clothes/shirts/jacket_leather_black_fit.png',
      thumbPath: 'assets/characters/clothes/shirts/jacket_leather_black.png',
      gender: 'all',
    ),
    ClothingItem(
      id: 'oversized_sweater',
      name: 'College Sweater',
      category: ClothingCategory.shirts,
      assetPath: 'assets/characters/clothes/shirts/oversized_sweater_fit.png',
      thumbPath: 'assets/characters/clothes/shirts/oversized_sweater.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'top_pink_hoodie',
      name: 'Pink Hoodie',
      category: ClothingCategory.shirts,
      assetPath: 'assets/characters/clothes/shirts/top_pink_hoodie_fit.png',
      thumbPath: 'assets/characters/clothes/shirts/top_pink_hoodie.png',
      gender: 'girl',
    ),

    // ── Bottoms / pants ──────────────────────────────────────────────────────

    ClothingItem(
      id: 'plaid_trousers',
      name: 'Plaid Trousers',
      category: ClothingCategory.pants,
      assetPath: 'assets/characters/clothes/pants/plaid_trousers.png',
      thumbPath: 'assets/characters/clothes/pants/plaid_trousers.png',
      gender: 'all',
      layer: _pantsLayer,
    ),
    ClothingItem(
      id: 'bottom_blue_jeans',
      name: 'Blue Jeans',
      category: ClothingCategory.pants,
      assetPath: 'assets/characters/clothes/pants/bottom_blue_jeans_fit.png',
      thumbPath: 'assets/characters/clothes/pants/bottom_blue_jeans.png',
      gender: 'all',
    ),

    // ── Shoes ────────────────────────────────────────────────────────────────

    ClothingItem(
      id: 'lace_up_boots',
      name: 'Lace-Up Boots',
      category: ClothingCategory.shoes,
      assetPath: 'assets/characters/clothes/shoes/lace_up_boots.png',
      thumbPath: 'assets/characters/clothes/shoes/lace_up_boots.png',
      gender: 'all',
      layer: _shoesLayer,
    ),
    ClothingItem(
      id: 'sneakers_white',
      name: 'White Sneakers',
      category: ClothingCategory.shoes,
      assetPath: 'assets/characters/clothes/shoes/sneakers_white_fit.png',
      thumbPath: 'assets/characters/clothes/shoes/sneakers_white.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'boots_black',
      name: 'Black Boots',
      category: ClothingCategory.shoes,
      assetPath: 'assets/characters/clothes/shoes/boots_black_fit.png',
      thumbPath: 'assets/characters/clothes/shoes/boots_black.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'acc_sneakers_white',
      name: 'Sneakers',
      category: ClothingCategory.shoes,
      assetPath: 'assets/characters/clothes/shoes/acc_sneakers_white_fit.png',
      gender: 'girl',
    ),

    // ── Accessories ──────────────────────────────────────────────────────────

    ClothingItem(
      id: 'glasses_round',
      name: 'Glasses',
      category: ClothingCategory.accessories,
      assetPath: 'assets/characters/clothes/accessories/glasses_round_fit.png',
      thumbPath: 'assets/characters/clothes/accessories/glasses_round.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'acc_cat_ears_headband',
      name: 'Cat Ears',
      category: ClothingCategory.accessories,
      assetPath:
          'assets/characters/clothes/accessories/acc_cat_ears_headband_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'acc_glasses_red',
      name: 'Red Glasses',
      category: ClothingCategory.accessories,
      assetPath:
          'assets/characters/clothes/accessories/acc_glasses_red_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'acc_headphones_black',
      name: 'Black Headphones',
      category: ClothingCategory.accessories,
      assetPath:
          'assets/characters/clothes/accessories/acc_headphones_black_fit.png',
      thumbPath:
          'assets/characters/clothes/accessories/acc_headphones_black.png',
      gender: 'boy',
      layer: _headphonesLayer,
    ),

    // ── Hair ─────────────────────────────────────────────────────────────────

    ClothingItem(
      id: 'girl_hair1',
      name: 'Style 1',
      category: ClothingCategory.hair,
      assetPath: 'assets/characters/hair/girl_tan_head_hair1_hair_only.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'girl_hair2',
      name: 'Style 2',
      category: ClothingCategory.hair,
      assetPath: 'assets/characters/hair/girl_light_head_hair2_hair_only.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'boy_hair1',
      name: 'Style 1',
      category: ClothingCategory.hair,
      assetPath: 'assets/characters/hair/boy_light_head_hair1_hair_only.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'boy_hair2',
      name: 'Style 2',
      category: ClothingCategory.hair,
      assetPath: 'assets/characters/hair/boy_light_head_hair2_hair_only.png',
      gender: 'boy',
    ),
  ];

  // ── Lookup helpers ─────────────────────────────────────────────────────────

  static ClothingItem byId(String id) {
    return clothingItems.firstWhere((item) => item.id == id);
  }

  static ClothingItem? tryById(String id) {
    try {
      return clothingItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<CharacterOption> hairOptionsFor(String gender) {
    return hairOptions
        .where((option) => option.gender == 'all' || option.gender == gender)
        .toList();
  }

  static List<CharacterOption> faceOptionsFor(String gender) {
    return faceOptions
        .where((option) => option.gender == 'all' || option.gender == gender)
        .toList();
  }

  static List<ClothingCategory> categoriesFor(String gender) {
    return ClothingCategory.values
        .where((category) => byCategory(category, gender).isNotEmpty)
        .toList();
  }

  static List<ClothingItem> byCategory(
    ClothingCategory category, [
    String? gender,
  ]) {
    return clothingItems.where((item) {
      final genderMatches =
          gender == null || item.gender == 'all' || item.gender == gender;
      return item.category == category && genderMatches;
    }).toList();
  }
}
