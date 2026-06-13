import 'clothing_item.dart';

enum CharacterGender { girl, boy }

class CharacterCustomization {
  final CharacterGender gender;
  final String skinTone;
  final String hairAsset;
  final String faceAsset;
  final Map<ClothingCategory, ClothingItem> outfit;

  /// Per-slot user-applied transform (drag / scale / rotate). Ephemeral.
  final Map<ClothingCategory, ItemTransform> transforms;

  /// Per-slot z-order override. Higher value = rendered on top. Ephemeral.
  final Map<ClothingCategory, int> zOrders;

  /// User-applied transform on the hair layer. Ephemeral.
  final ItemTransform hairTransform;

  const CharacterCustomization({
    required this.gender,
    required this.skinTone,
    required this.hairAsset,
    required this.faceAsset,
    required this.outfit,
    this.transforms = const {},
    this.zOrders = const {},
    this.hairTransform = const ItemTransform(),
  });

  // Default z-order for each clothing slot (lower = behind).
  static const _defaultZOrder = {
    ClothingCategory.dresses: 0,
    ClothingCategory.pants: 1,
    ClothingCategory.shirts: 2,
    ClothingCategory.shoes: 3,
    ClothingCategory.accessories: 5,
  };

  int zOrderOf(ClothingCategory category) =>
      zOrders[category] ?? _defaultZOrder[category] ?? 0;

  factory CharacterCustomization.initial() {
    return const CharacterCustomization(
      gender: CharacterGender.girl,
      skinTone: 'light',
      hairAsset: 'hair1',
      faceAsset: '',
      outfit: {},
      hairTransform: ItemTransform(),
    );
  }

  String get bodyAsset {
    if (gender == CharacterGender.girl && skinTone == 'light') {
      return 'assets/characters/body/girl_light_fit.png';
    }

    return 'assets/characters/body/${gender.name}_$skinTone.png';
  }

  String get hairStyle {
    if (hairAsset.contains('hair2') ||
        hairAsset.contains('bob_brown') ||
        hairAsset.contains('messy_brown') ||
        hairAsset.contains('undercut_blue')) {
      return 'hair2';
    }

    return 'hair1';
  }

  String get headHairAsset {
    final style = hairStyle;
    final isLight = skinTone != 'tan';

    if (gender == CharacterGender.girl) {
      if (style == 'hair2') {
        return isLight
            ? 'assets/characters/hair/girl_light_head_hair2_hair_only.png'
            : 'assets/characters/hair/girl_tan_head_hair2_hair_only.png';
      }
      // hair1: light variant is missing from assets, tan file used for both tones
      return 'assets/characters/hair/girl_tan_head_hair1_hair_only.png';
    }

    if (style == 'hair2') {
      return isLight
          ? 'assets/characters/hair/boy_light_head_hair2_hair_only.png'
          : 'assets/characters/hair/boy_tan_head_hair2_hair_only.png';
    }
    return isLight
        ? 'assets/characters/hair/boy_light_head_hair1_hair_only.png'
        : 'assets/characters/hair/boy_tan_head_hair1_hair_only.png';
  }

  /// Per-style, per-body-variant LayerSpec for the head-hair PNG.
  ///
  /// All values are derived from pixel measurements of each body PNG at the
  /// standard 240-wide doll frame (316.8 tall).  topFactor is the main
  /// variable; it shifts the hair to align its visible crown with each body's
  /// head crown, which differs by skin tone.
  LayerSpec get hairLayerSpec {
    final isLight = skinTone == 'light';
    final style = hairStyle;

    if (gender == CharacterGender.girl) {
      if (style == 'hair1') {
        // Silver bob — framing crop with transparent face hole.
        // girl_light crown y≈9.4px, girl_tan crown y≈14.2px in frame.
        return LayerSpec(
          centerX: 0.5,
          widthFactor: 0.443,
          heightFactor: 0.322,
          topFactor: isLight ? 0.013 : 0.029,
        );
      }
      // Purple twintails — hair-cap overlay.
      return LayerSpec(
        centerX: 0.5,
        widthFactor: 0.56,
        heightFactor: 0.43,
        topFactor: isLight ? -0.025 : -0.010,
      );
    }

    // Boy — wider spec to cover the broader skull.
    // boy_light/tan crowns are nearly equal (~11.8px), so one topFactor each.
    if (style == 'hair2') {
      // Brown messy — height-constrained in the box (aspect ~1.10).
      return const LayerSpec(
        centerX: 0.5,
        widthFactor: 0.50,
        heightFactor: 0.30,
        topFactor: 0.030,
      );
    }
    // Blue spiky — width-constrained (aspect ~1.34).
    return const LayerSpec(
      centerX: 0.5,
      widthFactor: 0.50,
      heightFactor: 0.30,
      topFactor: 0.020,
    );
  }

  CharacterCustomization copyWith({
    CharacterGender? gender,
    String? skinTone,
    String? hairAsset,
    String? faceAsset,
    Map<ClothingCategory, ClothingItem>? outfit,
    Map<ClothingCategory, ItemTransform>? transforms,
    Map<ClothingCategory, int>? zOrders,
    ItemTransform? hairTransform,
  }) {
    return CharacterCustomization(
      gender: gender ?? this.gender,
      skinTone: skinTone ?? this.skinTone,
      hairAsset: hairAsset ?? this.hairAsset,
      faceAsset: faceAsset ?? this.faceAsset,
      outfit: outfit ?? this.outfit,
      transforms: transforms ?? this.transforms,
      zOrders: zOrders ?? this.zOrders,
      hairTransform: hairTransform ?? this.hairTransform,
    );
  }
}
