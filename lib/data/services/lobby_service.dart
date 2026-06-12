import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LobbyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _botNames = [
    "Emma",
    "Chloe",
    "Choupette",
    "Bella",
    "Sofia",
    "Lily",
    "Clara",
    "Luna",
    "Maya",
    "Ambre",
  ];

  final List<String> _botAvatars = ["avatar1", "avatar2", "avatar3"];

  final List<String> _botDolls = [
    "assets/bots/poupee_chic.png",
    "assets/bots/poupee_gala.png",
    "assets/bots/poupee_cyber.png",
    "assets/bots/poupee_hiver.png",
  ];

  Future<String> findOrCreateLobby({
    required String currentUserId,
    required String currentUserNickname,
    required String currentUserAvatarId,
    required int userLevel,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('lobbies')
          .where('levelRequired', isEqualTo: userLevel)
          .where('status', isEqualTo: 'waiting')
          .where('playerCount', isLessThan: 4)
          .limit(1)
          .get();

      final Map<String, dynamic> myProfile = {
        'uid': currentUserId,
        'nickname': currentUserNickname,
        'avatarId': currentUserAvatarId,
        'isBot': false,
      };

      if (querySnapshot.docs.isNotEmpty) {
        final lobbyId = querySnapshot.docs.first.id;
        final DocumentReference lobbyRef =
            _firestore.collection('lobbies').doc(lobbyId);

        String finalLobbyId = await _firestore
            .runTransaction((transaction) async {
              DocumentSnapshot lobbySnapshot = await transaction.get(lobbyRef);

              if (!lobbySnapshot.exists) {
                throw Exception("Lobby_Inexistant");
              }

              Map<String, dynamic> data =
                  lobbySnapshot.data() as Map<String, dynamic>;
              List<dynamic> currentPlayers = data['players'] ?? [];
              int currentCount = data['playerCount'] ?? 0;
              String currentStatus = data['status'] ?? 'waiting';

              bool alreadyInLobby = currentPlayers.any(
                (player) => player['uid'] == currentUserId,
              );

              if (alreadyInLobby) {
                return lobbyId;
              }

              if (currentStatus != 'waiting' || currentCount >= 4) {
                throw Exception("Lobby_Plein");
              }

              int newCount = currentCount + 1;
              List<dynamic> updatedPlayers = List.from(currentPlayers)
                ..add(myProfile);

              Map<String, dynamic> updates = {
                'players': updatedPlayers,
                'playerCount': newCount,
              };

              if (newCount == 4) {
                updates['status'] = 'playing';
              }

              transaction.update(lobbyRef, updates);
              return lobbyId;
            })
            .catchError((error) async {
              if (error.toString().contains("Lobby_Plein") ||
                  error.toString().contains("Lobby_Inexistant")) {
                return await _createNewLobby(myProfile, userLevel);
              }
              throw error;
            });

        return finalLobbyId;
      } else {
        return await _createNewLobby(myProfile, userLevel);
      }
    } catch (e) {
      debugPrint("Matchmaking error: $e");
      rethrow;
    }
  }

  Future<String> _createNewLobby(
    Map<String, dynamic> creatorProfile,
    int userLevel,
  ) async {
    final newLobbyRef = _firestore.collection('lobbies').doc();
    List<String> themes = [
      "Modern Princess",
      "Gala Night",
      "Cyberpunk Look",
      "Winter Chic",
    ];
    String themeChoisi = (themes..shuffle()).first;

    await newLobbyRef.set({
      'lobbyId': newLobbyRef.id,
      'levelRequired': userLevel,
      'players': [creatorProfile],
      'playerCount': 1,
      'status': 'waiting',
      'theme': themeChoisi,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newLobbyRef.id;
  }

  Future<void> addSingleBot(String lobbyId) async {
    try {
      DocumentReference lobbyRef =
          _firestore.collection('lobbies').doc(lobbyId);
      final random = Random();

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(lobbyRef);
        if (!snapshot.exists) return;

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        String currentStatus = data['status'] ?? 'waiting';
        int currentCount = data['playerCount'] ?? 0;

        if (currentStatus != 'waiting' || currentCount >= 4) return;

        String botUid =
            "bot_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}";
        String botNickname = _botNames[random.nextInt(_botNames.length)];
        String botAvatarId = _botAvatars[random.nextInt(_botAvatars.length)];
        String chosenDollImage = _botDolls[random.nextInt(_botDolls.length)];

        Map<String, dynamic> newBot = {
          'uid': botUid,
          'nickname': botNickname,
          'avatarId': botAvatarId,
          'dollImage': chosenDollImage,
          'isBot': true,
        };

        int newCount = currentCount + 1;
        Map<String, dynamic> updates = {
          'players': FieldValue.arrayUnion([newBot]),
          'playerCount': newCount,
        };

        if (newCount == 4) {
          updates['status'] = 'playing';
        }

        transaction.update(lobbyRef, updates);
      });
    } catch (e) {
      debugPrint("Error adding bot: $e");
    }
  }
}
