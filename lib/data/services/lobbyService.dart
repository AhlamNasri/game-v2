import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class LobbyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🎭 Liste de pseudos pour générer des robots uniques
  final List<String> _botNames = [
    "Emma_Stylist",
    "Chloe_Fashion",
    "Choupette",
    "Bella_Doll",
    "Princesse_Sofia",
    "Lily_Pink",
    "Clara_Mode",
    "Diva_Glow",
    "Luna_Chic",
    "Zoé_Trend",
    "Maya_Vogue",
    "Ambre_Glam",
  ];

  final List<String> _botAvatars = ["avatar_1", "avatar_2", "avatar_3"];

  final List<String> _botDolls = [
    "assets/bots/poupee_chic.png",
    "assets/bots/poupee_gala.png",
    "assets/bots/poupee_cyber.png",
    "assets/bots/poupee_hiver.png",
  ];

  /// Trouve un salon existant ou en crée un nouveau sans doublon
  Future<String> findOrCreateLobby({
    required String currentUserId,
    required String currentUserNickname,
    required String currentUserAvatarId,
    required int userLevel,
  }) async {
    try {
      // 1. RECHERCHE : On cherche un lobby disponible
      final querySnapshot = await _firestore
          .collection('lobbies')
          .where('levelRequired', isEqualTo: userLevel)
          .where('status', isEqualTo: 'waiting')
          .where('playerCount', isLessThan: 4)
          .limit(1)
          .get();

      // Préparation de la fiche profil du joueur actuel
      final Map<String, dynamic> myProfile = {
        'uid': currentUserId,
        'nickname': currentUserNickname,
        'avatarId': currentUserAvatarId,
        'isBot': false,
      };

      // 2. DÉCISION
      if (querySnapshot.docs.isNotEmpty) {
        // CAS A : Un lobby existe potentiellement, on utilise une TRANSACTION pour éviter les doublons
        final lobbyId = querySnapshot.docs.first.id;
        final DocumentReference lobbyRef = _firestore
            .collection('lobbies')
            .doc(lobbyId);

        String finalLobbyId = await _firestore
            .runTransaction((transaction) async {
              DocumentSnapshot lobbySnapshot = await transaction.get(lobbyRef);

              if (!lobbySnapshot.exists) {
                // Si le salon a été supprimé entre-temps, on force la création d'un nouveau
                throw Exception("Lobby_Inexistant");
              }

              Map<String, dynamic> data =
                  lobbySnapshot.data() as Map<String, dynamic>;
              List<dynamic> currentPlayers = data['players'] ?? [];
              int currentCount = data['playerCount'] ?? 0;
              String currentStatus = data['status'] ?? 'waiting';

              // 🛡️ SÉCURITÉ ANTI-DOUBLON : On vérifie si l'utilisateur y est DÉJÀ
              bool alreadyInLobby = currentPlayers.any(
                (player) => player['uid'] == currentUserId,
              );

              if (alreadyInLobby) {
                print(
                  "🛑 [Alerte] L'utilisateur est déjà dans ce lobby. Blocage du doublon.",
                );
                return lobbyId; // On retourne l'ID direct sans rien modifier ni incrémenter !
              }

              // Si le salon est devenu complet ou a commencé pendant le clic
              if (currentStatus != 'waiting' || currentCount >= 4) {
                throw Exception("Lobby_Plein");
              }

              // Calcul des futures valeurs
              int newCount = currentCount + 1;
              List<dynamic> updatedPlayers = List.from(currentPlayers)
                ..add(myProfile);

              Map<String, dynamic> updates = {
                'players': updatedPlayers,
                'playerCount': newCount,
              };

              // Si la salle passe à 4 joueurs, on lance la partie
              if (newCount == 4) {
                updates['status'] = 'playing';
              }

              transaction.update(lobbyRef, updates);
              return lobbyId;
            })
            .catchError((error) async {
              // Si le salon était plein ou inexistant au moment de la transaction, on crée un salon frais
              if (error.toString().contains("Lobby_Plein") ||
                  error.toString().contains("Lobby_Inexistant")) {
                return await _createNewLobby(myProfile, userLevel);
              }
              throw error;
            });

        return finalLobbyId;
      } else {
        // CAS B : Aucun lobby disponible à la recherche, création directe
        return await _createNewLobby(myProfile, userLevel);
      }
    } catch (e) {
      print("Erreur lors du matchmaking : $e");
      rethrow;
    }
  }

  /// Fonction d'aide privée pour isoler la création d'un salon propre
  Future<String> _createNewLobby(
    Map<String, dynamic> creatorProfile,
    int userLevel,
  ) async {
    final newLobbyRef = _firestore.collection('lobbies').doc();
    List<String> themes = [
      "Princesse Moderne",
      "Soirée de Gala",
      "Look Cyberpunk",
      "Hiver Chic",
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

    print("🆕 Nouveau lobby créé avec l'ID : ${newLobbyRef.id}");
    return newLobbyRef.id;
  }

  /// Ajoute un seul robot (Protégé par transaction également)
  Future<void> addSingleBot(String lobbyId) async {
    try {
      DocumentReference lobbyRef = _firestore
          .collection('lobbies')
          .doc(lobbyId);
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
        print("🤖 Un robot a rejoint la salle ($newCount/4)");
      });
    } catch (e) {
      print("Erreur lors de l'ajout du robot unique : $e");
    }
  }
}
