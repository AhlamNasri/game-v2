import 'package:cloud_firestore/cloud_firestore.dart';

class LobbyService {
  final FirebaseFirestore _db;

  LobbyService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  Future<String> findOrCreateLobby({
    required String currentUserId,
    required int userLevel,
  }) async {
    final userId = currentUserId.trim();
    if (userId.isEmpty) {
      throw StateError('Utilisateur non authentifie');
    }

    final lobbies = _db.collection('lobbies');
    final candidates = await lobbies
        .where('status', isEqualTo: 'waiting')
        .limit(12)
        .get();

    for (final candidate in candidates.docs) {
      final joinedRoomId = await _tryJoinLobby(candidate.reference, userId);
      if (joinedRoomId != null) return joinedRoomId;
    }

    final lobbyRef = lobbies.doc();
    await lobbyRef.set({
      'roomId': lobbyRef.id,
      'hostId': userId,
      'playerIds': [userId],
      'players': [userId],
      'status': 'waiting',
      'hostLevel': userLevel,
      'averageLevel': userLevel,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return lobbyRef.id;
  }

  Future<String?> _tryJoinLobby(
    DocumentReference<Map<String, dynamic>> lobbyRef,
    String userId,
  ) {
    return _db.runTransaction<String?>((transaction) async {
      final snapshot = await transaction.get(lobbyRef);
      final data = snapshot.data();
      if (data == null) return null;

      final playerIds = List<String>.from(
        data['playerIds'] ?? data['players'] ?? const [],
      );
      final status = data['status'] as String?;

      if (status != 'waiting') return null;
      if (playerIds.contains(userId)) return snapshot.id;
      if (playerIds.length >= 2) return null;

      final updatedPlayerIds = [...playerIds, userId];
      transaction.update(lobbyRef, {
        'playerIds': updatedPlayerIds,
        'players': updatedPlayerIds,
        'status': 'ready',
        'guestId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return snapshot.id;
    });
  }
}
