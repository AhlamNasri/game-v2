import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/character_customization.dart';
import '../data/models/clothing_item.dart';
import '../data/repositories/fashion_catalog.dart';

final characterProvider =
    NotifierProvider<CharacterController, CharacterCustomization>(
  CharacterController.new,
);

class CharacterController extends Notifier<CharacterCustomization> {
  @override
  CharacterCustomization build() {
    return CharacterCustomization.initial();
  }

  void updateGender(CharacterGender gender) {
    if (gender == CharacterGender.boy) {
      state = state.copyWith(
        gender: gender,
        hairAsset: 'assets/characters/hair/hair_short_blue_fit.png',
        faceAsset: '',
        outfit: {},
      );
      return;
    }

    state = state.copyWith(
      gender: gender,
      hairAsset: 'assets/characters/hair/hair_blonde_twintails_fit.png',
      faceAsset: '',
      outfit: {},
    );
  }

  void updateSkinTone(String skinTone) {
    state = state.copyWith(skinTone: skinTone);
  }

  void updateHair(String hairAsset) {
    state = state.copyWith(hairAsset: hairAsset);
  }

  void updateFace(String faceAsset) {
    state = state.copyWith(faceAsset: faceAsset);
  }

  void resetOutfit() {
    state = state.copyWith(outfit: {});
  }

  void wear(ClothingItem item) {
    if (item.gender != 'all' && item.gender != state.gender.name) {
      return;
    }

    if (item.category == ClothingCategory.hair) {
      updateHair(item.assetPath);
      return;
    }

    final outfit = Map<ClothingCategory, ClothingItem>.from(state.outfit);

    final isSkirt = item.id == 'plaid_skirt';

    // Une robe complète (non-jupe) retire le pantalon ET le haut
    if (item.category == ClothingCategory.dresses && !isSkirt) {
      outfit.remove(ClothingCategory.pants);
      outfit.remove(ClothingCategory.shirts);
    }

    // Une jupe retire seulement le pantalon (garde le haut)
    if (item.category == ClothingCategory.dresses && isSkirt) {
      outfit.remove(ClothingCategory.pants);
    }

    // Un pantalon retire la robe complète (mais garde la jupe)
    if (item.category == ClothingCategory.pants) {
      final dress = outfit[ClothingCategory.dresses];
      // ✅ FIX : on retire la robe seulement si ce n'est pas une jupe
      if (dress != null && dress.id != 'plaid_skirt') {
        outfit.remove(ClothingCategory.dresses);
      }
    }

    // Un haut retire la robe complète (mais garde la jupe)
    if (item.category == ClothingCategory.shirts) {
      final dress = outfit[ClothingCategory.dresses];
      if (dress != null && dress.id != 'plaid_skirt') {
        outfit.remove(ClothingCategory.dresses);
      }
    }

    outfit[item.category] = item;
    state = state.copyWith(outfit: outfit);
  }

  // ✅ FIX : applyBestStyle utilise maintenant les bons vêtements
  // Garçon : veste cuir + jean + bottes (comme dans l'image 1)
  // Fille   : pull oversized + sneakers (comme dans l'image 2)
  void applyBestStyle() {
    if (state.gender == CharacterGender.boy) {
      state = state.copyWith(
        hairAsset: 'assets/characters/hair/hair_short_blue_fit.png',
        faceAsset: '',
        outfit: {
          ClothingCategory.shirts: FashionCatalog.byId('jacket_leather_black'),
          ClothingCategory.pants: FashionCatalog.byId('bottom_blue_jeans'),
          ClothingCategory.shoes: FashionCatalog.byId('boots_black'),
        },
      );
      return;
    }

    state = state.copyWith(
      hairAsset: 'assets/characters/hair/hair_blonde_twintails_fit.png',
      faceAsset: '',
      outfit: {
        ClothingCategory.dresses: FashionCatalog.byId('outfit_magical_girl'),
      },
    );
  }
}
