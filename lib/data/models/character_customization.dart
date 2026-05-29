import 'clothing_item.dart';

enum CharacterGender { girl, boy }

class CharacterCustomization {
  final CharacterGender gender;
  final String skinTone;
  final String hairAsset;
  final String faceAsset;
  final Map<ClothingCategory, ClothingItem> outfit;

  const CharacterCustomization({
    required this.gender,
    required this.skinTone,
    required this.hairAsset,
    required this.faceAsset,
    required this.outfit,
  });

  factory CharacterCustomization.initial() {
    return const CharacterCustomization(
      gender: CharacterGender.girl,
      skinTone: 'light',
      hairAsset: 'hair1',
      faceAsset: '',
      outfit: {},
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
    return 'assets/characters/hair/${gender.name}_${skinTone}_head_$hairStyle.png';
  }

  CharacterCustomization copyWith({
    CharacterGender? gender,
    String? skinTone,
    String? hairAsset,
    String? faceAsset,
    Map<ClothingCategory, ClothingItem>? outfit,
  }) {
    return CharacterCustomization(
      gender: gender ?? this.gender,
      skinTone: skinTone ?? this.skinTone,
      hairAsset: hairAsset ?? this.hairAsset,
      faceAsset: faceAsset ?? this.faceAsset,
      outfit: outfit ?? this.outfit,
    );
  }
}
