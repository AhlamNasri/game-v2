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
      'avatarUrl': avatarUrl, // Chaîne vide par défaut pour l'instant
      'level': 1, // NOMBRE ENTIER : Commence au niveau 1
      'price': 500, // NOMBRE ENTIER : On lui offre 500 pièces de départ !
      'boughtItems': [], // LISTE VIDE : Aucun objet acheté au début
      'createdAt': DateTime.now(),
    });
  }
}
