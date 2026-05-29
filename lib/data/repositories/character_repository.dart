import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/character_customization.dart';
import '../models/clothing_item.dart';
import 'fashion_catalog.dart';

class CharacterRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CharacterRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<CharacterCustomization?> load() async {
    final user = currentUser;
    if (user == null) return null;

    final snapshot = await _db.collection('user_characters').doc(user.uid).get();
    final data = snapshot.data();
    if (data != null) {
      return _fromMap(data);
    }

    final userSnapshot = await _db.collection('users').doc(user.uid).get();
    final userData = userSnapshot.data();
    final characterData = userData?['characterCustomization'];
    if (characterData is Map) {
      return _fromMap(Map<String, dynamic>.from(characterData));
    }

    return null;
  }

  Future<void> save(CharacterCustomization character) async {
    final user = currentUser;
    if (user == null) return;

    final data = _toMap(character);
    final payload = {
      ...data,
      'userId': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await Future.wait([
      _db
          .collection('user_characters')
          .doc(user.uid)
          .set(payload, SetOptions(merge: true)),
      _db.collection('users').doc(user.uid).set({
        'characterCustomization': payload,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    ]);
  }

  Map<String, dynamic> _toMap(CharacterCustomization character) {
    return {
      'gender': character.gender.name,
      'skinTone': character.skinTone,
      'hairAsset': character.hairAsset,
      'faceAsset': character.faceAsset,
      'outfitIds': character.outfit.map(
        (category, item) => MapEntry(category.name, item.id),
      ),
    };
  }

  CharacterCustomization _fromMap(Map<String, dynamic> data) {
    final genderName = data['gender'] as String?;
    final gender = CharacterGender.values.firstWhere(
      (value) => value.name == genderName,
      orElse: () => CharacterGender.girl,
    );
    final outfitIds = data['outfitIds'] is Map
        ? Map<String, dynamic>.from(data['outfitIds'] as Map)
        : const <String, dynamic>{};
    final outfit = <ClothingCategory, ClothingItem>{};

    for (final entry in outfitIds.entries) {
      final category = ClothingCategory.values.where(
        (value) => value.name == entry.key,
      );
      if (category.isEmpty || entry.value is! String) continue;

      final item = FashionCatalog.clothingItems.where(
        (item) => item.id == entry.value,
      );
      if (item.isNotEmpty) {
        outfit[category.first] = item.first;
      }
    }

    return CharacterCustomization(
      gender: gender,
      skinTone: data['skinTone'] as String? ?? 'light',
      hairAsset: _normalizeHairAsset(
        data['hairAsset'] as String? ?? _defaultHairFor(gender),
      ),
      faceAsset: data['faceAsset'] as String? ?? '',
      outfit: outfit,
    );
  }

  String _defaultHairFor(CharacterGender gender) {
    return 'hair1';
  }

  String _normalizeHairAsset(String hairAsset) {
    if (hairAsset == 'hair1' || hairAsset == 'hair2') {
      return hairAsset;
    }

    if (hairAsset.contains('hair2') ||
        hairAsset.contains('bob_brown') ||
        hairAsset.contains('messy_brown') ||
        hairAsset.contains('undercut_blue')) {
      return 'hair2';
    }

    return 'hair1';
  }
}
