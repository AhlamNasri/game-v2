class AppUser {
  final String uid;
  final String nickname;
  final String email;
  final String avatarId;
  final int level;
  final int xp;
  final int coins;
  final List<String> boughtItems;

  const AppUser({
    required this.uid,
    required this.nickname,
    required this.email,
    required this.avatarId,
    required this.level,
    required this.xp,
    required this.coins,
    required this.boughtItems,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      nickname: data['nickname'] as String? ?? '',
      email: data['email'] as String? ?? '',
      avatarId: data['avatarId'] as String? ?? 'avatar1',
      level: data['level'] as int? ?? 1,
      xp: data['xp'] as int? ?? 0,
      coins: data['coins'] as int? ?? 0,
      boughtItems: List<String>.from(data['boughtItems'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'nickname': nickname,
    'email': email,
    'avatarId': avatarId,
    'level': level,
    'xp': xp,
    'coins': coins,
    'boughtItems': boughtItems,
  };
}
