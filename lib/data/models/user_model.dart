import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nickname;
  final String email;
  final String avatarId;
  final int level;
  final int xp;
  final int coins;
  final List<String> ownedItems;

  UserModel({
    required this.uid,
    required this.nickname,
    required this.email,
    required this.avatarId,
    required this.level,
    required this.xp,
    required this.coins,
    required this.ownedItems,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nickname: data['nickname'] ?? '',
      email: data['email'] ?? '',
      avatarId: data['avatarId'] ?? 'default_girl',
      level: data['level'] ?? 1,
      xp: data['xp'] ?? 0,
      coins: data['coins'] ?? 100,
      ownedItems: List<String>.from(data['ownedItems'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'email': email,
      'avatarId': avatarId,
      'level': level,
      'xp': xp,
      'coins': coins,
      'ownedItems': ownedItems,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
