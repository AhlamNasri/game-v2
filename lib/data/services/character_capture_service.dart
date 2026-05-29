import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/character_customization.dart';

class CharacterCaptureService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<String> saveCapture({
    required Uint8List bytes,
    required CharacterCustomization character,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Connecte-toi avant de sauvegarder la photo.');
    }

    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'users/${user.uid}/character_captures/$createdAt.png';
    final ref = _storage.ref(storagePath);

    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/png'),
    );

    final downloadUrl = await ref.getDownloadURL();
    final captureData = <String, dynamic>{
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'gender': character.gender.name,
      'skinTone': character.skinTone,
      'hairAsset': character.hairAsset,
      'outfitIds': character.outfit.map(
        (category, item) => MapEntry(category.name, item.id),
      ),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final userRef = _db.collection('users').doc(user.uid);
    await userRef.set({
      'latestCharacterCapture': captureData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await userRef.collection('character_captures').add(captureData);

    return downloadUrl;
  }
}
