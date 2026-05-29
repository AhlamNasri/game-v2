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
      hairAsset: 'assets/characters/hair/hair_blonde_twintails_fit.png',
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
