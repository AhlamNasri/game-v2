import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_room_girls/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🟢 1. Fonction pour sauvegarder les infos localement sur le téléphone
  Future<void> saveUserLocally({
    required String uid,
    required String nickname,
    required String avatarId,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', uid);
    await prefs.setString('user_nickname', nickname);
    await prefs.setString('user_avatarId', avatarId);
    print("Données utilisateur sauvegardées localement !");
  }

  // 🟢 2. Fonction pour récupérer les infos locales (Utile au démarrage du jeu)
  Future<Map<String, String?>> getLocalUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'uid': prefs.getString('user_uid'),
      'nickname': prefs.getString('user_nickname'),
      'avatarId': prefs.getString('user_avatarId'),
    };
  }

  Future<void> clearLocalUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('uid'),
      prefs.remove('user_uid'),
      prefs.remove('user_nickname'),
      prefs.remove('user_avatarId'),
    ]);
  }

  // Ta fonction de création modifiée pour inclure la sauvegarde automatique
  Future<UserModel> createAnonymousPlayer({
    required String nickname,
    required String avatarId,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      String uniqueUid = userCredential.user!.uid;

      UserModel newPlayer = UserModel(
        uid: uniqueUid,
        nickname: nickname,
        email: "invite@mode.com",
        avatarId: avatarId,
        level: 1,
        xp: 0,
        coins: 500,
        ownedItems: ["robe_initiale"],
      );

      // Enregistrement sur Firebase Cloud Firestore
      await _firestore
          .collection('users')
          .doc(uniqueUid)
          .set(newPlayer.toMap());

      // 🟢 SAUVEGARDE LOCALE : On stocke les infos dans SharedPreferences juste après !
      await saveUserLocally(
        uid: uniqueUid,
        nickname: nickname,
        avatarId: avatarId,
      );

      print("Joueur invité créé et stocké localement !");
      return newPlayer;
    } catch (e) {
      print("Erreur : $e");
      rethrow;
    }
  }
}
