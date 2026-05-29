// room_repository.dart
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_definition.dart';
import 'room_save_state.dart';

class RoomUnlockException implements Exception {
  final String message;

  const RoomUnlockException(this.message);

  @override
  String toString() => message;
}

class RoomLoadException implements Exception {
  final String message;

  const RoomLoadException(this.message);

  @override
  String toString() => message;
}

class _RoomUnlockSettings {
  final int initialUnlockCost;
  final int unlockCostMultiplier;
  final String defaultBackground;

  const _RoomUnlockSettings({
    required this.initialUnlockCost,
    required this.unlockCostMultiplier,
    required this.defaultBackground,
  });
}

class RoomRepository {
  static const _settingsCollection = 'room_settings';
  static const _settingsDocument = 'default';
  static const _roomsCollection = 'rooms';
  static const _userRoomsCollection = 'user_rooms';
  static const _usersCollection = 'users';

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RoomRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<RoomSaveState> load() async {
    final user = currentUser;
    if (user == null) return RoomSaveState.guest();

    final results = await Future.wait([
      _db.collection(_userRoomsCollection).doc(user.uid).get(),
      _db.collection(_usersCollection).doc(user.uid).get(),
    ]);

    final roomSnap = results[0];
    final userSnap = results[1];
    final userData = userSnap.data() ?? {};
    final roomData = roomSnap.data() ?? {};
    final catalog = await _loadCatalogOrFallback(roomData);

    if (catalog.isEmpty && !roomSnap.exists) {
      throw const RoomLoadException(
        'Room configuration is missing in Firebase. Add enabled room documents to the rooms collection.',
      );
    }

    if (!roomSnap.exists) {
      final initial = RoomSaveState.initial(
        user.uid,
        [catalog.first],
        nextLockedRoom: catalog.length > 1 ? catalog[1] : null,
        coins: _readInt(userData, const [
          'coins',
          'gems',
          'price',
        ], fallback: 0),
        playerLevel: ((userData['level'] ?? 1) as num).toInt(),
      );
      await _db
          .collection(_userRoomsCollection)
          .doc(user.uid)
          .set(initial.toMap(), SetOptions(merge: true));
      return initial;
    }

    final state = RoomSaveState.fromMap(user.uid, roomData, userData, catalog);
    return state;
  }

  Future<void> save(RoomSaveState state) async {
    if (state.userId == 'guest') return;
    await _db
        .collection(_userRoomsCollection)
        .doc(state.userId)
        .set(state.toMap(), SetOptions(merge: true));
  }

  Future<RoomSaveState> unlockNextRoom(RoomSaveState current) async {
    final user = currentUser;
    if (user == null || current.userId == 'guest') {
      throw const RoomUnlockException('Please sign in to unlock rooms.');
    }

    final roomToUnlock = current.nextLockedRoom;
    if (roomToUnlock == null) {
      throw const RoomUnlockException(
        'No locked rooms are configured in Firebase yet.',
      );
    }

    final cost = roomToUnlock.unlockCost;
    final userRef = _db.collection(_usersCollection).doc(user.uid);
    final userRoomRef = _db.collection(_userRoomsCollection).doc(user.uid);

    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final roomSnap = await transaction.get(userRoomRef);
      if (!userSnap.exists) {
        throw const RoomUnlockException('User profile is missing.');
      }

      final userData = userSnap.data() ?? const <String, dynamic>{};
      final coins = _readInt(userData, const [
        'coins',
        'gems',
        'price',
      ], fallback: 0);
      if (coins < cost) {
        throw RoomUnlockException(
          'Need $cost coins to unlock ${roomToUnlock.name}.',
        );
      }

      final roomData = roomSnap.data() ?? const <String, dynamic>{};
      final unlockedRoomIds = roomData['unlockedRoomIds'] is List
          ? List<String>.from(roomData['unlockedRoomIds'] as List)
          : current.rooms.map((room) => room.id).toList();

      if (!unlockedRoomIds.contains(roomToUnlock.id)) {
        unlockedRoomIds.add(roomToUnlock.id);
      }

      transaction.set(userRef, {
        'coins': coins - cost,
      }, SetOptions(merge: true));
      transaction.set(userRoomRef, {
        'userId': user.uid,
        'unlockedRoomIds': unlockedRoomIds,
        'activeRoomId': roomToUnlock.id,
        'activeRoomIndex': unlockedRoomIds.length - 1,
        'roomStates': {
          roomToUnlock.id: {'placedItems': const []},
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    return load();
  }

  Future<List<RoomDefinition>> _loadCatalogOrFallback(
    Map<String, dynamic> roomData,
  ) async {
    try {
      final catalog = await _loadCatalog();
      if (catalog.isNotEmpty) return catalog;
    } on FirebaseException {
      // Fall back to the user's existing Firebase room document so the room
      // screen can still open while global room config/rules are fixed.
    }

    return _legacyRoomsFromUserRoom(roomData);
  }

  Future<List<RoomDefinition>> _loadCatalog() async {
    final settings = await _loadSettings();
    final snapshot = await _db.collection(_roomsCollection).get();
    final entries =
        snapshot.docs
            .map((doc) {
              final data = doc.data();
              final enabled = data['enabled'];
              if (enabled == false) return null;
              final order = ((data['order'] ?? 0) as num).toInt();
              final unlockCost = data['unlockCost'] is num
                  ? (data['unlockCost'] as num).toInt()
                  : _unlockCostForOrder(order, settings);
              final room = RoomDefinition.fromMap({
                ...data,
                'id': (data['id'] ?? doc.id).toString(),
                'unlockCost': unlockCost,
              }, order);
              return MapEntry(order, room);
            })
            .whereType<MapEntry<int, RoomDefinition>>()
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => entry.value).toList();
  }

  List<RoomDefinition> _legacyRoomsFromUserRoom(Map<String, dynamic> roomData) {
    final rawRooms = roomData['rooms'] is List
        ? roomData['rooms'] as List
        : null;
    if (rawRooms == null || rawRooms.isEmpty) return const [];
    return rawRooms
        .whereType<Map>()
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => RoomDefinition.fromMap(
            Map<String, dynamic>.from(entry.value),
            entry.key,
          ),
        )
        .toList();
  }

  int _unlockCostForOrder(int order, _RoomUnlockSettings settings) {
    if (order <= 0) return 0;
    return (settings.initialUnlockCost *
            math.pow(settings.unlockCostMultiplier, order - 1))
        .round();
  }

  Future<_RoomUnlockSettings> _loadSettings() async {
    final ref = _db.collection(_settingsCollection).doc(_settingsDocument);
    final DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await ref.get();
    } on FirebaseException {
      return const _RoomUnlockSettings(
        initialUnlockCost: 2000,
        unlockCostMultiplier: 2,
        defaultBackground: '',
      );
    }
    if (!snap.exists) {
      return const _RoomUnlockSettings(
        initialUnlockCost: 2000,
        unlockCostMultiplier: 2,
        defaultBackground: '',
      );
    }

    final data = snap.data() ?? const <String, dynamic>{};
    return _RoomUnlockSettings(
      initialUnlockCost: ((data['initialUnlockCost'] ?? 2000) as num).toInt(),
      unlockCostMultiplier: ((data['unlockCostMultiplier'] ?? 2) as num)
          .toInt(),
      defaultBackground: (data['defaultBackground'] ?? '').toString(),
    );
  }

  int _readInt(
    Map<String, dynamic> data,
    List<String> keys, {
    required int fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toInt();
    }
    return fallback;
  }
}
