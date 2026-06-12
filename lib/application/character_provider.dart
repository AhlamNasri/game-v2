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
    Future.microtask(applyBestStyle);
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
    state = state.copyWith(
      gender: gender,
      hairAsset: 'hair1',
      faceAsset: '',
      outfit: {},
      transforms: {},
      zOrders: {},
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
    state = state.copyWith(outfit: {}, transforms: {}, zOrders: {});
    _saveCurrent();
  }

  // ── Interactive transform controls ─────────────────────────────────────────

  /// Update the position / scale / rotation of one clothing slot.
  /// Called on every gesture tick — does NOT persist to avoid Firestore spam.
  void updateTransform(ClothingCategory category, ItemTransform transform) {
    final transforms =
        Map<ClothingCategory, ItemTransform>.from(state.transforms);
    transforms[category] = transform;
    state = state.copyWith(transforms: transforms);
  }

  /// Update the hair layer transform (drag / scale / rotate). Not persisted.
  void updateHairTransform(ItemTransform transform) {
    state = state.copyWith(hairTransform: transform);
  }

  /// Reset hair transform back to the spec default.
  void resetHairTransform() {
    state = state.copyWith(hairTransform: const ItemTransform());
  }

  /// Reset a slot's transform back to the LayerSpec default.
  void resetTransform(ClothingCategory category) {
    final transforms =
        Map<ClothingCategory, ItemTransform>.from(state.transforms);
    transforms.remove(category);
    state = state.copyWith(transforms: transforms);
  }

  /// Move a slot one step closer to the viewer (higher z-order).
  void raiseLayer(ClothingCategory category) {
    final zOrders = Map<ClothingCategory, int>.from(state.zOrders);
    zOrders[category] = state.zOrderOf(category) + 1;
    state = state.copyWith(zOrders: zOrders);
  }

  /// Move a slot one step further from the viewer (lower z-order).
  void lowerLayer(ClothingCategory category) {
    final zOrders = Map<ClothingCategory, int>.from(state.zOrders);
    final current = state.zOrderOf(category);
    if (current > 0) zOrders[category] = current - 1;
    state = state.copyWith(zOrders: zOrders);
  }

  /// Remove a single item from the outfit and clear its transform.
  void unequip(ClothingCategory category) {
    final outfit = Map<ClothingCategory, ClothingItem>.from(state.outfit);
    final transforms =
        Map<ClothingCategory, ItemTransform>.from(state.transforms);
    outfit.remove(category);
    transforms.remove(category);
    state = state.copyWith(outfit: outfit, transforms: transforms);
    _saveCurrent();
  }

  // ── Slot logic ─────────────────────────────────────────────────────────────

  /// Skirt-type items occupy the dress slot but only cover the legs,
  /// so they can be paired with a separate top.
  static const _skirtIds = {'plaid_skirt', 'skirt_long'};

  void wear(ClothingItem item) {
    if (item.gender != 'all' && item.gender != state.gender.name) return;

    if (item.category == ClothingCategory.hair) {
      // Store the canonical style id ('hair1' or 'hair2'), not the asset path.
      // headHairAsset resolves the right PNG per gender without skinTone coupling.
      updateHair(item.id.endsWith('hair2') ? 'hair2' : 'hair1');
      return;
    }

    final outfit = Map<ClothingCategory, ClothingItem>.from(state.outfit);
    final wornDress = outfit[ClothingCategory.dresses];
    final wornDressIsSkirt =
        wornDress != null && _skirtIds.contains(wornDress.id);

    switch (item.category) {
      case ClothingCategory.dresses:
        outfit.remove(ClothingCategory.pants);
        if (!_skirtIds.contains(item.id)) {
          outfit.remove(ClothingCategory.shirts);
        }
      case ClothingCategory.pants:
        outfit.remove(ClothingCategory.dresses);
      case ClothingCategory.shirts:
        if (wornDress != null && !wornDressIsSkirt) {
          outfit.remove(ClothingCategory.dresses);
        }
      case ClothingCategory.shoes:
      case ClothingCategory.accessories:
      case ClothingCategory.hair:
        break;
    }

    outfit[item.category] = item;
    state = state.copyWith(outfit: outfit);
    _saveCurrent();
  }

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
        ClothingCategory.dresses: FashionCatalog.byId('plaid_skirt'),
        ClothingCategory.shirts: FashionCatalog.byId('top_pink_hoodie'),
        ClothingCategory.shoes: FashionCatalog.byId('sneakers_white'),
      },
    );
    _saveCurrent();
  }

  void _saveCurrent() {
    if (_isLoadingFromFirebase) return;
    unawaited(_repository.save(state).catchError((_) {}));
  }
}
