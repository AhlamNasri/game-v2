import 'package:cloud_firestore/cloud_firestore.dart';

class LobbyPlayer {
  final String uid;
  final String nickname;
  final String avatarId;
  final bool isBot;
  final String? dollImage;

  const LobbyPlayer({
    required this.uid,
    required this.nickname,
    required this.avatarId,
    required this.isBot,
    this.dollImage,
  });

  factory LobbyPlayer.fromMap(Map<String, dynamic> data) {
    return LobbyPlayer(
      uid: data['uid'] as String? ?? '',
      nickname: data['nickname'] as String? ?? '',
      avatarId: data['avatarId'] as String? ?? 'avatar1',
      isBot: data['isBot'] as bool? ?? false,
      dollImage: data['dollImage'] as String?,
    );
  }
}

class Competition {
  final String lobbyId;
  final int levelRequired;
  final List<LobbyPlayer> players;
  final int playerCount;
  final String status;
  final String theme;
  final Timestamp? createdAt;

  const Competition({
    required this.lobbyId,
    required this.levelRequired,
    required this.players,
    required this.playerCount,
    required this.status,
    required this.theme,
    this.createdAt,
  });

  factory Competition.fromFirestore(Map<String, dynamic> data) {
    final playersList = (data['players'] as List<dynamic>? ?? [])
        .map((p) => LobbyPlayer.fromMap(p as Map<String, dynamic>))
        .toList();
    return Competition(
      lobbyId: data['lobbyId'] as String? ?? '',
      levelRequired: data['levelRequired'] as int? ?? 1,
      players: playersList,
      playerCount: data['playerCount'] as int? ?? 0,
      status: data['status'] as String? ?? 'waiting',
      theme: data['theme'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
