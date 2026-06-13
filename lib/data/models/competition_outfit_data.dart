import '../repositories/fashion_catalog.dart';
import 'character_customization.dart';
import 'clothing_item.dart';

Map<String, dynamic> competitionOutfitDataFromCharacter(
  CharacterCustomization character, {
  String? imageUrl,
}) {
  final outfitIds = character.outfit.map(
    (category, item) => MapEntry(category.name, item.id),
  );
  final outfitAssets = character.outfit.map(
    (category, item) => MapEntry(category.name, item.assetPath),
  );
  final outfitNames = character.outfit.map(
    (category, item) => MapEntry(category.name, item.name),
  );

  return {
    'source': 'dressing',
    'gender': character.gender.name,
    'skinTone': character.skinTone,
    'hairAsset': character.hairAsset,
    'faceAsset': character.faceAsset,
    'bodyAsset': character.bodyAsset,
    'headHairAsset': character.headHairAsset,
    'outfitIds': outfitIds,
    'outfitAssets': outfitAssets,
    'outfitNames': outfitNames,
    if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
  };
}

CharacterCustomization characterFromCompetitionOutfitData(
  Map<String, dynamic> data,
) {
  final genderName = data['gender']?.toString();
  final gender = CharacterGender.values.firstWhere(
    (value) => value.name == genderName,
    orElse: () => CharacterGender.girl,
  );

  final rawOutfitIds = data['outfitIds'];
  final outfitIds = rawOutfitIds is Map
      ? Map<String, dynamic>.from(rawOutfitIds)
      : const <String, dynamic>{};
  final outfit = <ClothingCategory, ClothingItem>{};

  for (final entry in outfitIds.entries) {
    final category = _categoryByName(entry.key);
    final itemId = entry.value?.toString();
    if (category == null || itemId == null || itemId.isEmpty) continue;

    final item = FashionCatalog.tryById(itemId);
    if (item != null) outfit[category] = item;
  }

  return CharacterCustomization(
    gender: gender,
    skinTone: data['skinTone']?.toString().trim().isNotEmpty == true
        ? data['skinTone'].toString().trim()
        : 'light',
    hairAsset: _readHairAsset(data),
    faceAsset: data['faceAsset']?.toString() ?? '',
    outfit: outfit,
  );
}

String? competitionOutfitImageUrl(Map<String, dynamic> data) {
  final value = data['imageUrl']?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

ClothingCategory? _categoryByName(String name) {
  for (final category in ClothingCategory.values) {
    if (category.name == name) return category;
  }
  return null;
}

String _readHairAsset(Map<String, dynamic> data) {
  final hairAsset = data['hairAsset']?.toString().trim();
  if (hairAsset != null && hairAsset.isNotEmpty) return hairAsset;

  final legacyHair = data['hair']?.toString().trim();
  if (legacyHair != null && legacyHair.isNotEmpty) return legacyHair;

  return 'hair1';
}
