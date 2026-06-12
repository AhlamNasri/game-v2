import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

class AuthService {
  void createUser({
    required String uid,
    required String nickname,
    required String email,
    required String avatarUrl,
  }) async {
    var userDocument = firestore.collection('users').doc(uid);
    await userDocument.set({
      'nickname': nickname.trim(),
      'email': email.trim(),
      'avatarUrl': avatarUrl,
      'level': 1,
      'xp': 0,
      'coins': 500,
      'boughtItems': [],
      'createdAt': DateTime.now(),
    });
  }
}
