import '../models/clothing_item.dart';

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

class FashionCatalog {
  static const skinTones = [
    CharacterOption(
      label: 'Clair',
      value: 'light',
      assetPath: 'assets/characters/body/girl_light_fit.png',
    ),
    CharacterOption(
      label: 'Mat',
      value: 'tan',
      assetPath: 'assets/characters/body/girl_tan.png',
    ),
  ];

  static const hairOptions = [
    CharacterOption(
      label: 'Style 1',
      value: 'hair1',
      assetPath: 'assets/characters/hair/girl_light_head_hair1.png',
      gender: 'girl',
    ),
    CharacterOption(
      label: 'Style 1',
      value: 'hair1',
      assetPath: 'assets/characters/hair/boy_light_head_hair1.png',
      gender: 'boy',
    ),
    CharacterOption(
      label: 'Style 2',
      value: 'hair2',
      assetPath: 'assets/characters/hair/boy_light_head_hair2.png',
      gender: 'boy',
    ),
    CharacterOption(
      label: 'Style 2',
      value: 'hair2',
      assetPath: 'assets/characters/hair/girl_light_head_hair2.png',
      gender: 'girl',
    ),
  ];

  static const faceOptions = <CharacterOption>[];

  static const clothingItems = [
    ClothingItem(
      id: 'dress_gothic_lolita',
      name: 'Robe gothic',
      category: ClothingCategory.dresses,
      assetPath:
          'assets/characters/clothes/dresses/dress_gothic_lolita_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'plaid_skirt',
      name: 'Jupe carreaux',
      category: ClothingCategory.dresses,
      assetPath: 'assets/characters/clothes/dresses/plaid_skirt_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'outfit_casual_hoodie',
      name: 'Hoodie jaune',
      category: ClothingCategory.dresses,
      assetPath:
          'assets/characters/clothes/dresses/outfit_casual_hoodie_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'outfit_cool_jacket',
      name: 'Veste cool',
      category: ClothingCategory.dresses,
      assetPath: 'assets/characters/clothes/dresses/outfit_cool_jacket_fit.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'outfit_magical_girl',
      name: 'Magique',
      category: ClothingCategory.dresses,
      assetPath:
          'assets/characters/clothes/dresses/outfit_magical_girl_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'outfit_school_uniform',
      name: 'Uniforme',
      category: ClothingCategory.dresses,
      assetPath:
          'assets/characters/clothes/dresses/outfit_school_uniform_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'outfit_sporty_tracksuit',
      name: 'Survetement',
      category: ClothingCategory.dresses,
      assetPath:
          'assets/characters/clothes/dresses/outfit_sporty_tracksuit_fit.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'outfit_summer_dress',
      name: 'Robe ete',
      category: ClothingCategory.dresses,
      assetPath:
          'assets/characters/clothes/dresses/outfit_summer_dress_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'outfit_wizard_robe',
      name: 'Magicien',
      category: ClothingCategory.dresses,
      assetPath:
          'assets/characters/clothes/dresses/outfit_wizard_robe_fit.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'boy_outfit_cool_jacket',
      name: 'Veste cool',
      category: ClothingCategory.dresses,
      assetPath:
          'assets/characters/clothes/dresses/boy_outfit_cool_jacket_fit.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'boy_outfit_hero',
      name: 'Aventurier',
      category: ClothingCategory.dresses,
      assetPath: 'assets/characters/clothes/dresses/boy_outfit_hero_fit.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'boy_outfit_sporty',
      name: 'Survetement',
      category: ClothingCategory.dresses,
      assetPath: 'assets/characters/clothes/dresses/boy_outfit_sporty_fit.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'jacket_leather_black',
      name: 'Veste cuir',
      category: ClothingCategory.shirts,
      assetPath:
          'assets/characters/clothes/shirts/jacket_leather_black_fit.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'sneakers_white',
      name: 'Baskets blanches',
      category: ClothingCategory.shoes,
      assetPath: 'assets/characters/clothes/shoes/sneakers_white_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'boots_black',
      name: 'Bottes noires',
      category: ClothingCategory.shoes,
      assetPath: 'assets/characters/clothes/shoes/boots_black_fit.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'acc_sneakers_white',
      name: 'Sneakers',
      category: ClothingCategory.shoes,
      assetPath: 'assets/characters/clothes/shoes/acc_sneakers_white_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'bottom_blue_jeans',
      name: 'Jean bleu',
      category: ClothingCategory.pants,
      assetPath: 'assets/characters/clothes/pants/bottom_blue_jeans_fit.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'oversized_sweater',
      name: 'Pull college',
      category: ClothingCategory.shirts,
      assetPath: 'assets/characters/clothes/shirts/oversized_sweater_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'top_pink_hoodie',
      name: 'Hoodie rose',
      category: ClothingCategory.shirts,
      assetPath: 'assets/characters/clothes/shirts/top_pink_hoodie_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'glasses_round',
      name: 'Lunettes',
      category: ClothingCategory.accessories,
      assetPath: 'assets/characters/clothes/accessories/glasses_round_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'acc_cat_ears_headband',
      name: 'Oreilles chat',
      category: ClothingCategory.accessories,
      assetPath:
          'assets/characters/clothes/accessories/acc_cat_ears_headband_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'acc_glasses_red',
      name: 'Lunettes rouges',
      category: ClothingCategory.accessories,
      assetPath: 'assets/characters/clothes/accessories/acc_glasses_red_fit.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'acc_headphones_black',
      name: 'Casque noir',
      category: ClothingCategory.accessories,
      assetPath:
          'assets/characters/clothes/accessories/acc_headphones_black_fit.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'girl_hair1',
      name: 'Style 1',
      category: ClothingCategory.hair,
      assetPath: 'assets/characters/hair/girl_light_head_hair1.png',
      gender: 'girl',
    ),
    ClothingItem(
      id: 'boy_hair1',
      name: 'Style 1',
      category: ClothingCategory.hair,
      assetPath: 'assets/characters/hair/boy_light_head_hair1.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'boy_hair2',
      name: 'Style 2',
      category: ClothingCategory.hair,
      assetPath: 'assets/characters/hair/boy_light_head_hair2.png',
      gender: 'boy',
    ),
    ClothingItem(
      id: 'girl_hair2',
      name: 'Style 2',
      category: ClothingCategory.hair,
      assetPath: 'assets/characters/hair/girl_light_head_hair2.png',
      gender: 'girl',
    ),
  ];

  static ClothingItem byId(String id) {
    return clothingItems.firstWhere((item) => item.id == id);
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
    final categories = ClothingCategory.values.where((category) {
      return byCategory(category, gender).isNotEmpty;
    }).toList();

    return categories;
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
