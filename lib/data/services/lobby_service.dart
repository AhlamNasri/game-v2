import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LobbyService {
  static const int maxPlayers = 4;
  static const Duration waitingLobbyLifetime = Duration(minutes: 5);
  static const Duration playDuration = Duration(minutes: 3);
  static const Duration votingDuration = Duration(seconds: 45);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final math.Random _random = math.Random();

  final List<String> _botNames = [
    'Emma',
    'Chloe',
    'Choupette',
    'Bella',
    'Sofia',
    'Lily',
    'Clara',
    'Diva',
    'Luna',
    'Zoe',
    'Maya',
    'Ambre',
  ];

  final List<String> _botAvatars = ['avatar1', 'avatar2', 'avatar3'];

  final List<String> _botDolls = [
    'assets/bots/avatar4.png',
    'assets/bots/avatar5.png',
    'assets/bots/avatar6.png',
    'assets/bots/avatar7.png',
  ];

  Future<String> findOrCreateLobby({
    required String currentUserId,
    required String currentUserNickname,
    required String currentUserAvatarId,
    required int userLevel,
  }) async {
    final userId = currentUserId.trim();
    if (userId.isEmpty) throw StateError('Utilisateur non authentifie');

    final profile = _humanProfile(
      uid: userId,
      nickname: currentUserNickname,
      avatarId: currentUserAvatarId,
    );

    final existingLobbyId = await _findActiveLobbyForUser(userId);
    if (existingLobbyId != null) return existingLobbyId;

    // Query only by status so no composite index is required.
    // playerCount filter is applied in Dart to avoid needing a Firestore index.
    final querySnapshot = await _firestore
        .collection('lobbies')
        .where('status', isEqualTo: 'waiting')
        .limit(20)
        .get();

    final candidates = querySnapshot.docs.where((doc) {
      final count = doc.data()['playerCount'] as int? ?? 0;
      return count < maxPlayers;
    }).toList();

    for (final candidate in candidates) {
      final lobbyId = await _tryJoinLobby(candidate.reference, profile);
      if (lobbyId != null) return lobbyId;
    }

    return _createNewLobby(profile, userLevel);
  }

  Future<void> addSingleBot(
    String lobbyId, {
    required String requestedByUserId,
  }) async {
    final requesterId = requestedByUserId.trim();
    if (lobbyId.trim().isEmpty || requesterId.isEmpty) return;

    final lobbyRef = _firestore.collection('lobbies').doc(lobbyId);

    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(lobbyRef);
      final data = snapshot.data();
      if (data == null) return;

      final players = _playersFrom(data);
      final playerIds = _playerIdsFrom(data, players);
      final hostId = (data['hostId'] as String?) ?? _firstHumanId(players);
      final status = data['status'] as String? ?? 'waiting';

      if (status != 'waiting') return;
      if (hostId != requesterId) return;
      if (_isExpired(data)) {
        transaction.update(lobbyRef, _statusUpdate('expired'));
        return;
      }
      if (players.length >= maxPlayers || playerIds.length >= maxPlayers) {
        transaction.update(lobbyRef, _statusUpdate('playing'));
        return;
      }

      final bot = _botProfile(lobbyId);
      final updatedPlayers = [...players, bot];
      final updatedPlayerIds = [...playerIds, bot['uid'] as String];

      transaction.update(lobbyRef, {
        'players': updatedPlayers,
        'playerIds': updatedPlayerIds,
        'playerCount': updatedPlayers.length,
        'status': updatedPlayers.length >= maxPlayers ? 'playing' : 'waiting',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }).catchError((e) {
      debugPrint('Error adding bot: $e');
    });
  }

  Future<void> leaveLobby({
    required String lobbyId,
    required String userId,
  }) async {
    final cleanLobbyId = lobbyId.trim();
    final cleanUserId = userId.trim();
    if (cleanLobbyId.isEmpty || cleanUserId.isEmpty) return;

    final lobbyRef = _firestore.collection('lobbies').doc(cleanLobbyId);

    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(lobbyRef);
      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'] as String? ?? 'waiting';
      if (status != 'waiting') return;

      final players = _playersFrom(data);
      final playerIds = _playerIdsFrom(data, players);
      if (!playerIds.contains(cleanUserId)) return;

      final remainingPlayers =
          players.where((p) => p['uid'] != cleanUserId).toList();
      final remainingHumans =
          remainingPlayers.where((p) => p['isBot'] != true).toList();

      if (remainingHumans.isEmpty) {
        transaction.update(lobbyRef, {
          'players': <Map<String, dynamic>>[],
          'playerIds': <String>[],
          'playerCount': 0,
          'hostId': null,
          'status': 'abandoned',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final nextHostId = remainingHumans.first['uid'] as String;
      transaction.update(lobbyRef, {
        'players': remainingPlayers,
        'playerIds': remainingPlayers
            .map((p) => p['uid'] as String)
            .toList(),
        'playerCount': remainingPlayers.length,
        'hostId': nextHostId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> ensurePlayWindow({
    required String lobbyId,
    required String requestedByUserId,
  }) async {
    final cleanLobbyId = lobbyId.trim();
    final requesterId = requestedByUserId.trim();
    if (cleanLobbyId.isEmpty || requesterId.isEmpty) return;

    final lobbyRef = _firestore.collection('lobbies').doc(cleanLobbyId);

    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(lobbyRef);
      final data = snapshot.data();
      if (data == null) return;

      final players = _playersFrom(data);
      final playerIds = _playerIdsFrom(data, players);
      if (!playerIds.contains(requesterId)) return;

      final status = data['status'] as String? ?? 'waiting';
      if (status != 'playing') return;
      if (data['playEndsAt'] is Timestamp) return;

      final now = DateTime.now();
      transaction.update(lobbyRef, {
        'playStartedAt': Timestamp.fromDate(now),
        'playEndsAt': Timestamp.fromDate(now.add(playDuration)),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> submitHumanOutfit({
    required String lobbyId,
    required String userId,
    required String username,
    required Map<String, dynamic> outfitData,
    required bool finishedInTime,
  }) async {
    final cleanLobbyId = lobbyId.trim();
    final cleanUserId = userId.trim();
    if (cleanLobbyId.isEmpty || cleanUserId.isEmpty) return;

    final lobbyRef = _firestore.collection('lobbies').doc(cleanLobbyId);
    final outfitRef =
        lobbyRef.collection('submitted_outfits').doc(cleanUserId);

    await _firestore.runTransaction<void>((transaction) async {
      final lobbySnapshot = await transaction.get(lobbyRef);
      final data = lobbySnapshot.data();
      if (data == null) return;

      final status = data['status'] as String? ?? 'waiting';
      if (status != 'playing') return;

      final players = _playersFrom(data);
      final player = _playerById(players, cleanUserId);
      if (player == null || player['isBot'] == true) return;

      final outfitSnapshot = await transaction.get(outfitRef);
      final existingData = outfitSnapshot.data();
      final votesCount = existingData?['votesCount'] is num
          ? (existingData!['votesCount'] as num).toInt()
          : 0;
      final submittedIds = _submittedPlayerIds(data)..add(cleanUserId);

      transaction.set(
        outfitRef,
        {
          'userId': cleanUserId,
          'username': _clean(username, fallback: 'Joueur'),
          'outfitData': outfitData,
          'submittedAt': FieldValue.serverTimestamp(),
          'finishedInTime': finishedInTime,
          'isBot': false,
          'votesCount': votesCount,
        },
        SetOptions(merge: true),
      );

      transaction.update(lobbyRef, {
        'submittedPlayerIds': submittedIds.toList(),
        'submittedPlayerCount': submittedIds.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> completePlayIfReady({
    required String lobbyId,
    required String requestedByUserId,
    bool force = false,
  }) async {
    final cleanLobbyId = lobbyId.trim();
    final requesterId = requestedByUserId.trim();
    if (cleanLobbyId.isEmpty || requesterId.isEmpty) return;

    final lobbyRef = _firestore.collection('lobbies').doc(cleanLobbyId);

    await _firestore.runTransaction<void>((transaction) async {
      final lobbySnapshot = await transaction.get(lobbyRef);
      final data = lobbySnapshot.data();
      if (data == null) return;

      final status = data['status'] as String? ?? 'waiting';
      if (status != 'playing') return;

      final players = _playersFrom(data);
      final playerIds = _playerIdsFrom(data, players);
      if (!playerIds.contains(requesterId)) return;

      final humanPlayers =
          players.where((p) => p['isBot'] != true).toList();
      final botPlayers = players.where((p) => p['isBot'] == true);
      final submittedIds = _submittedPlayerIds(data);

      final humanOutfits =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final player in humanPlayers) {
        final uid = player['uid'] as String;
        final ref = lobbyRef.collection('submitted_outfits').doc(uid);
        final snap = await transaction.get(ref);
        humanOutfits[uid] = snap;
        if (snap.exists) submittedIds.add(uid);
      }

      final playEndsAt = data['playEndsAt'];
      final timeExpired =
          playEndsAt is Timestamp &&
          !playEndsAt.toDate().isAfter(DateTime.now());
      final allHumansSubmitted =
          humanPlayers.every((p) => submittedIds.contains(p['uid']));

      if (!force && !timeExpired && !allHumansSubmitted) return;

      for (final player in humanPlayers) {
        final uid = player['uid'] as String;
        if (humanOutfits[uid]?.exists == true) continue;

        transaction.set(
          lobbyRef.collection('submitted_outfits').doc(uid),
          {
            'userId': uid,
            'username': _clean(
              player['nickname']?.toString() ?? '',
              fallback: 'Joueur',
            ),
            'outfitData': _defaultHumanOutfit(),
            'submittedAt': FieldValue.serverTimestamp(),
            'finishedInTime': false,
            'isBot': false,
            'votesCount': 0,
          },
          SetOptions(merge: true),
        );
        submittedIds.add(uid);
      }

      if (data['botsSubmitted'] != true) {
        for (final bot in botPlayers) {
          final uid = bot['uid'] as String;
          transaction.set(
            lobbyRef.collection('submitted_outfits').doc(uid),
            {
              'userId': uid,
              'username': _clean(
                bot['nickname']?.toString() ?? '',
                fallback: 'Bot Styliste',
              ),
              'outfitData': {
                'isBotOutfit': true,
                'imageUrl': _clean(
                  bot['dollImage']?.toString() ?? '',
                  fallback: 'assets/bots/avatar4.png',
                ),
              },
              'submittedAt': FieldValue.serverTimestamp(),
              'finishedInTime': true,
              'isBot': true,
              'votesCount': 0,
            },
            SetOptions(merge: true),
          );
        }
      }

      transaction.update(lobbyRef, {
        'status': 'voting',
        'submittedPlayerIds': submittedIds.toList(),
        'submittedPlayerCount': submittedIds.length,
        'botsSubmitted': true,
        'votingStartedAt': FieldValue.serverTimestamp(),
        'votingEndsAt':
            Timestamp.fromDate(DateTime.now().add(votingDuration)),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<bool> castVote({
    required String lobbyId,
    required String voterId,
    required String targetUserId,
  }) async {
    final cleanLobbyId = lobbyId.trim();
    final cleanVoterId = voterId.trim();
    final cleanTargetId = targetUserId.trim();
    if (cleanLobbyId.isEmpty ||
        cleanVoterId.isEmpty ||
        cleanTargetId.isEmpty) {
      throw StateError('Vote invalide');
    }
    if (cleanVoterId == cleanTargetId) {
      throw StateError('Impossible de voter pour soi-meme');
    }

    final lobbyRef = _firestore.collection('lobbies').doc(cleanLobbyId);
    final targetRef =
        lobbyRef.collection('submitted_outfits').doc(cleanTargetId);

    return _firestore.runTransaction<bool>((transaction) async {
      final lobbySnapshot = await transaction.get(lobbyRef);
      final data = lobbySnapshot.data();
      if (data == null) throw StateError('Salle introuvable');

      final status = data['status'] as String? ?? 'waiting';
      if (status != 'voting') return false;

      final players = _playersFrom(data);
      final voter = _playerById(players, cleanVoterId);
      if (voter == null || voter['isBot'] == true) return false;

      final votedIds = _votedPlayerIds(data);
      if (votedIds.contains(cleanVoterId)) return false;

      final targetSnapshot = await transaction.get(targetRef);
      if (!targetSnapshot.exists) return false;

      transaction.update(targetRef, {'votesCount': FieldValue.increment(1)});

      votedIds.add(cleanVoterId);
      transaction.update(lobbyRef, {
        'votedPlayerIds': votedIds.toList(),
        'votedPlayerCount': votedIds.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  Future<void> completeVotingIfReady({
    required String lobbyId,
    required String requestedByUserId,
    bool force = false,
  }) async {
    final cleanLobbyId = lobbyId.trim();
    final requesterId = requestedByUserId.trim();
    if (cleanLobbyId.isEmpty || requesterId.isEmpty) return;

    final lobbyRef = _firestore.collection('lobbies').doc(cleanLobbyId);
    final outfitDocs =
        (await lobbyRef.collection('submitted_outfits').get()).docs;
    final outfitRefs = outfitDocs.map((d) => d.reference).toList();

    await _firestore.runTransaction<void>((transaction) async {
      final lobbySnapshot = await transaction.get(lobbyRef);
      final data = lobbySnapshot.data();
      if (data == null) return;

      final status = data['status'] as String? ?? 'waiting';
      if (status != 'voting' && status != 'results') return;
      if (status == 'results' && data['rewardsGranted'] == true) return;

      final players = _playersFrom(data);
      final playerIds = _playerIdsFrom(data, players);
      if (!playerIds.contains(requesterId)) return;

      final humanPlayers =
          players.where((p) => p['isBot'] != true).toList();
      final votedIds = _votedPlayerIds(data);
      final allHumansVoted =
          humanPlayers.every((p) => votedIds.contains(p['uid']));
      final votingEndsAt = data['votingEndsAt'];
      final timeExpired =
          votingEndsAt is Timestamp &&
          !votingEndsAt.toDate().isAfter(DateTime.now());
      final canForceWithoutClock = force && votingEndsAt is! Timestamp;

      if (status == 'voting' &&
          !timeExpired &&
          !allHumansVoted &&
          !canForceWithoutClock) {
        return;
      }

      final outfits = <Map<String, dynamic>>[];
      for (final ref in outfitRefs) {
        final snap = await transaction.get(ref);
        final outfitData = snap.data();
        if (outfitData == null) continue;

        outfits.add({
          'id': snap.id,
          'ref': ref,
          'isBot': outfitData['isBot'] == true,
          'votesCount': _readInt(outfitData, 'votesCount'),
          'username': _clean(
            outfitData['username']?.toString() ?? '',
            fallback: 'Joueur',
          ),
        });
      }

      if (outfits.isEmpty) return;

      final userSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final player in humanPlayers) {
        final uid = player['uid'] as String;
        userSnapshots[uid] = await transaction
            .get(_firestore.collection('users').doc(uid));
      }

      if (data['robotVotesSubmitted'] != true) {
        final botOutfits =
            outfits.where((o) => o['isBot'] == true).toList();
        for (final botOutfit in botOutfits) {
          final validTargets =
              outfits.where((o) => o['id'] != botOutfit['id']).toList();
          if (validTargets.isEmpty) continue;

          final target =
              validTargets[_random.nextInt(validTargets.length)];
          target['votesCount'] = (target['votesCount'] as int) + 1;
          transaction.update(
            target['ref'] as DocumentReference<Map<String, dynamic>>,
            {'votesCount': FieldValue.increment(1)},
          );
        }
      }

      outfits.sort((a, b) {
        final cmp = (b['votesCount'] as int)
            .compareTo(a['votesCount'] as int);
        if (cmp != 0) return cmp;
        return (a['id'] as String).compareTo(b['id'] as String);
      });

      final rewards = _grantRewards(
        transaction: transaction,
        rankedOutfits: outfits,
        humanPlayers: humanPlayers,
        votedIds: votedIds,
        userSnapshots: userSnapshots,
      );

      transaction.update(lobbyRef, {
        'status': 'results',
        'robotVotesSubmitted': true,
        'rewardsGranted': true,
        'ranking': _rankingPayload(outfits),
        'rewards': rewards,
        'resultsFinalizedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── private helpers ────────────────────────────────────

  Future<String?> _findActiveLobbyForUser(String userId) async {
    final snapshot = await _firestore
        .collection('lobbies')
        .where('playerIds', arrayContains: userId)
        .limit(10)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'waiting';
      if (status != 'waiting' && status != 'playing') continue;

      final players = _playersFrom(data);
      if (!players.any((p) => p['uid'] == userId)) continue;

      if (status == 'waiting' && _isExpired(data)) {
        await doc.reference.update(_statusUpdate('expired'));
        continue;
      }

      return doc.id;
    }

    return null;
  }

  Future<String?> _tryJoinLobby(
    DocumentReference<Map<String, dynamic>> lobbyRef,
    Map<String, dynamic> profile,
  ) {
    return _firestore.runTransaction<String?>((transaction) async {
      final snapshot = await transaction.get(lobbyRef);
      final data = snapshot.data();
      if (data == null) return null;

      final status = data['status'] as String? ?? 'waiting';
      if (status != 'waiting') return null;

      if (_isExpired(data)) {
        transaction.update(lobbyRef, _statusUpdate('expired'));
        return null;
      }

      final players = _playersFrom(data);
      final playerIds = _playerIdsFrom(data, players);
      final userId = profile['uid'] as String;

      if (playerIds.contains(userId)) return lobbyRef.id;
      if (players.length >= maxPlayers || playerIds.length >= maxPlayers) {
        return null;
      }

      final updatedPlayers = [...players, profile];
      final updatedPlayerIds = [...playerIds, userId];

      transaction.update(lobbyRef, {
        'players': updatedPlayers,
        'playerIds': updatedPlayerIds,
        'playerCount': updatedPlayers.length,
        'status': updatedPlayers.length >= maxPlayers ? 'playing' : 'waiting',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return lobbyRef.id;
    });
  }

  Future<String> _createNewLobby(
    Map<String, dynamic> creatorProfile,
    int userLevel,
  ) async {
    final lobbyRef = _firestore.collection('lobbies').doc();
    final userId = creatorProfile['uid'] as String;

    await lobbyRef.set({
      'lobbyId': lobbyRef.id,
      'roomId': lobbyRef.id,
      'hostId': userId,
      'levelRequired': userLevel,
      'players': [creatorProfile],
      'playerIds': [userId],
      'playerCount': 1,
      'maxPlayers': maxPlayers,
      'status': 'waiting',
      'theme': _randomTheme(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(waitingLobbyLifetime),
      ),
    });

    return lobbyRef.id;
  }

  Map<String, dynamic> _humanProfile({
    required String uid,
    required String nickname,
    required String avatarId,
  }) {
    return {
      'uid': uid,
      'nickname': _clean(nickname, fallback: 'Joueur'),
      'avatarId': _clean(avatarId, fallback: 'avatar_doux'),
      'isBot': false,
    };
  }

  Map<String, dynamic> _botProfile(String lobbyId) {
    return {
      'uid':
          'bot_${lobbyId}_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(100000)}',
      'nickname': _botNames[_random.nextInt(_botNames.length)],
      'avatarId': _botAvatars[_random.nextInt(_botAvatars.length)],
      'dollImage': _botDolls[_random.nextInt(_botDolls.length)],
      'isBot': true,
    };
  }

  List<Map<String, dynamic>> _playersFrom(Map<String, dynamic> data) {
    final rawPlayers = data['players'];
    if (rawPlayers is! List) return [];

    final players = <Map<String, dynamic>>[];
    for (final raw in rawPlayers) {
      if (raw is! Map) continue;
      final player = Map<String, dynamic>.from(raw);
      final uid = player['uid']?.toString().trim();
      if (uid == null || uid.isEmpty) continue;
      players.add({
        ...player,
        'uid': uid,
        'nickname': _clean(
          player['nickname']?.toString() ??
              player['name']?.toString() ??
              '',
          fallback: 'Joueur',
        ),
        'avatarId': _clean(
          player['avatarId']?.toString() ?? '',
          fallback: 'avatar_doux',
        ),
        'isBot': player['isBot'] == true,
      });
    }

    return players;
  }

  List<String> _playerIdsFrom(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> players,
  ) {
    final rawPlayerIds = data['playerIds'];
    if (rawPlayerIds is List) {
      return rawPlayerIds
          .map((id) => id.toString().trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
    }
    return players.map((p) => p['uid'] as String).toSet().toList();
  }

  Map<String, dynamic>? _playerById(
    List<Map<String, dynamic>> players,
    String userId,
  ) {
    for (final player in players) {
      if (player['uid'] == userId) return player;
    }
    return null;
  }

  String? _firstHumanId(List<Map<String, dynamic>> players) {
    for (final player in players) {
      if (player['isBot'] != true) return player['uid'] as String;
    }
    return null;
  }

  Set<String> _submittedPlayerIds(Map<String, dynamic> data) {
    final raw = data['submittedPlayerIds'];
    if (raw is! List) return <String>{};
    return raw
        .map((id) => id.toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Set<String> _votedPlayerIds(Map<String, dynamic> data) {
    final raw = data['votedPlayerIds'];
    if (raw is! List) return <String>{};
    return raw
        .map((id) => id.toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Map<String, Map<String, int>> _grantRewards({
    required Transaction transaction,
    required List<Map<String, dynamic>> rankedOutfits,
    required List<Map<String, dynamic>> humanPlayers,
    required Set<String> votedIds,
    required Map<String, DocumentSnapshot<Map<String, dynamic>>> userSnapshots,
  }) {
    final rewards = <String, Map<String, int>>{};
    final humanIds =
        humanPlayers.map((p) => p['uid'] as String).toSet();

    for (final player in humanPlayers) {
      final uid = player['uid'] as String;
      final rankIndex =
          rankedOutfits.indexWhere((o) => o['id'] == uid);
      if (rankIndex == -1) continue;

      final outfit = rankedOutfits[rankIndex];
      final rank = _rankForOutfit(rankedOutfits, outfit);
      final placement = _placementReward(rank);
      final votedBonusXp = votedIds.contains(uid) ? 5 : 0;
      final xp = 20 + votedBonusXp + placement['xp']!;
      final coins = 10 + placement['coins']!;

      final userData =
          userSnapshots[uid]?.data() ?? const <String, dynamic>{};
      final oldLevel = _readInt(userData, 'level', fallback: 1);
      final oldXp = _readInt(userData, 'xp', fallback: 0);
      final oldCoins = _readInt(userData, 'coins', fallback: 0);

      var newLevel = oldLevel;
      var newXp = oldXp + xp;
      while (newXp >= _xpGoalForLevel(newLevel) && newLevel < 99) {
        newXp -= _xpGoalForLevel(newLevel);
        newLevel += 1;
      }

      rewards[uid] = {
        'rank': rank,
        'xp': xp,
        'coins': coins,
        'oldLevel': oldLevel,
        'newLevel': newLevel,
        'oldXp': oldXp,
        'newXp': newXp,
        'oldCoins': oldCoins,
        'newCoins': oldCoins + coins,
        'nextLevelXp': _xpGoalForLevel(newLevel),
      };

      transaction.set(
        _firestore.collection('users').doc(uid),
        {
          'level': newLevel,
          'xp': newXp,
          'coins': oldCoins + coins,
          'lastCompetitionRewardAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    for (final outfit in rankedOutfits) {
      final uid = outfit['id'] as String;
      if (!humanIds.contains(uid)) continue;
      final reward = rewards[uid];
      if (reward == null) continue;

      transaction.set(
        outfit['ref'] as DocumentReference<Map<String, dynamic>>,
        {'reward': reward},
        SetOptions(merge: true),
      );
    }

    return rewards;
  }

  Map<String, int> _placementReward(int rank) {
    switch (rank) {
      case 1:
        return {'xp': 50, 'coins': 50};
      case 2:
        return {'xp': 30, 'coins': 25};
      case 3:
        return {'xp': 20, 'coins': 15};
      default:
        return {'xp': 0, 'coins': 0};
    }
  }

  List<Map<String, dynamic>> _rankingPayload(
      List<Map<String, dynamic>> rankedOutfits) {
    return [
      for (final outfit in rankedOutfits)
        {
          'rank': _rankForOutfit(rankedOutfits, outfit),
          'userId': outfit['id'],
          'username': outfit['username'],
          'isBot': outfit['isBot'],
          'votesCount': outfit['votesCount'],
        },
    ];
  }

  int _rankForOutfit(
    List<Map<String, dynamic>> rankedOutfits,
    Map<String, dynamic> outfit,
  ) {
    final votes = (outfit['votesCount'] as int?) ?? 0;
    return rankedOutfits
            .where((o) => ((o['votesCount'] as int?) ?? 0) > votes)
            .length +
        1;
  }

  int _readInt(Map<String, dynamic> data, String key,
      {int fallback = 0}) {
    final value = data[key];
    return value is num ? value.toInt() : fallback;
  }

  int _xpGoalForLevel(int level) => 120 + (level.clamp(1, 99) * 80);

  bool _isExpired(Map<String, dynamic> data) {
    final expiresAt = data['expiresAt'];
    if (expiresAt is! Timestamp) return false;
    return expiresAt.toDate().isBefore(DateTime.now());
  }

  Map<String, dynamic> _statusUpdate(String status) =>
      {'status': status, 'updatedAt': FieldValue.serverTimestamp()};

  String _randomTheme() {
    const themes = [
      'Modern Princess',
      'Gala Night',
      'Cyberpunk Look',
      'Winter Chic',
    ];
    return themes[_random.nextInt(themes.length)];
  }

  String _clean(String value, {required String fallback}) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  Map<String, dynamic> _defaultHumanOutfit() => const {
        'source': 'default',
        'gender': 'girl',
        'skinTone': 'light',
        'hairAsset': 'hair1',
        'outfitIds': <String, String>{},
      };
}
