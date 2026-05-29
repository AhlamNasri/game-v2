// room_save_state.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room_definition.dart';
import '../models/room_item.dart';
import 'room_assets.dart';

class RoomSaveState {
  final String userId;
  final List<String> inventory;
  final List<RoomDefinition> rooms;
  final int activeRoomIndex;
  final RoomDefinition? nextLockedRoom;
  final int coins;
  final int playerLevel;

  RoomSaveState({
    required this.userId,
    required this.inventory,
    required this.rooms,
    required this.activeRoomIndex,
    this.nextLockedRoom,
    required this.coins,
    required this.playerLevel,
  });

  bool get canUnlockRoom => nextLockedRoom != null;

  int? get nextUnlockCost => nextLockedRoom?.unlockCost;

  factory RoomSaveState.initial(
    String userId,
    List<RoomDefinition> rooms, {
    RoomDefinition? nextLockedRoom,
    int coins = 0,
    int playerLevel = 1,
  }) => RoomSaveState(
    userId: userId,
    inventory: const [],
    rooms: rooms,
    activeRoomIndex: 0,
    nextLockedRoom: nextLockedRoom,
    coins: coins,
    playerLevel: playerLevel,
  );

  factory RoomSaveState.guest() => RoomSaveState(
    userId: 'guest',
    inventory: const [],
    rooms: [
      RoomDefinition(
        id: 'room_1',
        name: 'Guest Room',
        background: RoomAssets.defaultBackground,
        placedItems: const [],
      ),
    ],
    activeRoomIndex: 0,
    coins: 0,
    playerLevel: 1,
  );

  factory RoomSaveState.fromMap(
    String userId,
    Map<String, dynamic> roomData,
    Map<String, dynamic> userData,
    List<RoomDefinition> catalog,
  ) {
    final rawRooms = roomData['rooms'] is List
        ? roomData['rooms'] as List
        : null;
    final rawRoomStates = roomData['roomStates'] is Map
        ? roomData['roomStates'] as Map
        : null;
    final unlockedRoomIds = roomData['unlockedRoomIds'] is List
        ? List<String>.from(roomData['unlockedRoomIds'] as List)
        : const <String>[];
    final legacyItems = roomData['placedItems'] is List
        ? roomData['placedItems'] as List
        : const [];

    final legacyRooms = rawRooms == null || rawRooms.isEmpty
        ? [
            RoomDefinition(
              id: 'room_1',
              name: 'Room 1',
              background: RoomAssets.defaultBackground,
              placedItems: legacyItems
                  .whereType<Map>()
                  .map(
                    (item) => RoomItem.fromMap(Map<String, dynamic>.from(item)),
                  )
                  .toList(),
            ),
          ]
        : rawRooms
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

    final legacyById = {for (final room in legacyRooms) room.id: room};
    final hasUnlockList = unlockedRoomIds.isNotEmpty;
    final catalogSource = catalog.isEmpty ? legacyRooms : catalog;
    final unlocked = <RoomDefinition>[];
    RoomDefinition? nextLocked;

    for (var index = 0; index < catalogSource.length; index++) {
      final config = catalogSource[index];
      final isUnlocked = hasUnlockList
          ? unlockedRoomIds.contains(config.id)
          : index == 0 || legacyById.containsKey(config.id);

      final rawState = rawRoomStates?[config.id];
      final stateMap = rawState is Map
          ? Map<String, dynamic>.from(rawState)
          : const <String, dynamic>{};
      final rawItems = stateMap['placedItems'] is List
          ? stateMap['placedItems'] as List
          : legacyById[config.id]?.placedItems
                    .map((item) => item.toMap())
                    .toList() ??
                const [];
      final room = RoomDefinition(
        id: config.id,
        name: config.name,
        background: config.background,
        unlockCost: config.unlockCost,
        placedItems: rawItems
            .whereType<Map>()
            .map((item) => RoomItem.fromMap(Map<String, dynamic>.from(item)))
            .toList(),
      );

      if (isUnlocked) {
        unlocked.add(room);
      } else {
        nextLocked ??= room;
      }
    }

    final rooms = unlocked.isEmpty && catalogSource.isNotEmpty
        ? [
            RoomDefinition(
              id: catalogSource.first.id,
              name: catalogSource.first.name,
              background: catalogSource.first.background,
              unlockCost: catalogSource.first.unlockCost,
              placedItems: const [],
            ),
          ]
        : unlocked;

    final active = ((roomData['activeRoomIndex'] ?? 0) as num).toInt();
    final activeRoomId = roomData['activeRoomId']?.toString();
    final activeIndex = activeRoomId == null
        ? active.clamp(0, rooms.length - 1).toInt()
        : rooms.indexWhere((room) => room.id == activeRoomId);

    return RoomSaveState(
      userId: userId,
      inventory: List<String>.from(roomData['inventory'] ?? const []),
      rooms: rooms,
      activeRoomIndex: activeIndex < 0 ? 0 : activeIndex,
      nextLockedRoom: nextLocked,
      coins: _readInt(userData, const ['coins', 'gems', 'price'], fallback: 0),
      playerLevel: ((userData['level'] ?? 1) as num).toInt(),
    );
  }

  static int _readInt(
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

  RoomSaveState copyWith({
    List<String>? inventory,
    List<RoomDefinition>? rooms,
    int? activeRoomIndex,
    RoomDefinition? nextLockedRoom,
    bool clearNextLockedRoom = false,
    int? coins,
    int? playerLevel,
  }) {
    return RoomSaveState(
      userId: userId,
      inventory: inventory ?? this.inventory,
      rooms: rooms ?? this.rooms,
      activeRoomIndex: activeRoomIndex ?? this.activeRoomIndex,
      nextLockedRoom: clearNextLockedRoom
          ? null
          : nextLockedRoom ?? this.nextLockedRoom,
      coins: coins ?? this.coins,
      playerLevel: playerLevel ?? this.playerLevel,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'inventory': inventory,
    'unlockedRoomIds': rooms.map((room) => room.id).toList(),
    'activeRoomId': rooms[activeRoomIndex].id,
    'roomStates': {
      for (final room in rooms)
        room.id: {
          'placedItems': room.placedItems.map((item) => item.toMap()).toList(),
        },
    },
    'rooms': rooms.map((room) => room.toMap()).toList(),
    'activeRoomIndex': activeRoomIndex,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
