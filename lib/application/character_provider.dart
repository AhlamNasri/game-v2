import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/character_customization.dart';
import '../data/models/clothing_item.dart';
import '../data/repositories/character_repository.dart';
import '../data/repositories/fashion_catalog.dart';

final characterProvider =
    NotifierProvider<CharacterController, CharacterCustomization>(
  CharacterController.new,
);

class CharacterController extends Notifier<CharacterCustomization> {
  final _repository = CharacterRepository();
  bool _isLoadingFromFirebase = false;

  @override
  CharacterCustomization build() {
    Future.microtask(loadSavedCharacter);
    return CharacterCustomization.initial();
  }

  Future<void> loadSavedCharacter() async {
    _isLoadingFromFirebase = true;
    try {
      final savedCharacter = await _repository.load();
      if (savedCharacter != null) {
        state = savedCharacter;
      }
    } catch (_) {
      // Keep the default character if Firebase is unavailable.
    } finally {
      _isLoadingFromFirebase = false;
    }
  }

  void updateGender(CharacterGender gender) {
    if (gender == CharacterGender.boy) {
      state = state.copyWith(
        gender: gender,
        hairAsset: 'hair1',
        faceAsset: '',
        outfit: {},
      );
      _saveCurrent();
      return;
    }

    state = state.copyWith(
      gender: gender,
      hairAsset: 'hair1',
      faceAsset: '',
      outfit: {},
    );
    _saveCurrent();
  }

  void updateSkinTone(String skinTone) {
    state = state.copyWith(skinTone: skinTone);
    _saveCurrent();
  }

  void updateHair(String hairAsset) {
    state = state.copyWith(hairAsset: hairAsset);
    _saveCurrent();
  }

  void updateFace(String faceAsset) {
    state = state.copyWith(faceAsset: faceAsset);
    _saveCurrent();
  }

  void resetOutfit() {
    state = state.copyWith(outfit: {});
    _saveCurrent();
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
    _saveCurrent();
  }

  // ✅ FIX : applyBestStyle utilise maintenant les bons vêtements
  // Garçon : veste cuir + jean + bottes (comme dans l'image 1)
  // Fille   : pull oversized + sneakers (comme dans l'image 2)
  void applyBestStyle() {
    if (state.gender == CharacterGender.boy) {
      state = state.copyWith(
        hairAsset: 'hair1',
        faceAsset: '',
        outfit: {
          ClothingCategory.shirts: FashionCatalog.byId('jacket_leather_black'),
          ClothingCategory.pants: FashionCatalog.byId('bottom_blue_jeans'),
          ClothingCategory.shoes: FashionCatalog.byId('boots_black'),
        },
      );
      _saveCurrent();
      return;
    }

    state = state.copyWith(
      hairAsset: 'hair1',
      faceAsset: '',
      outfit: {
        ClothingCategory.dresses: FashionCatalog.byId('outfit_magical_girl'),
      },
    );
    _saveCurrent();
  }

  void _saveCurrent() {
    if (_isLoadingFromFirebase) return;
    unawaited(_repository.save(state).catchError((_) {}));
  }
}
