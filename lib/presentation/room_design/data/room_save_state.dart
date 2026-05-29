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
  // coins and playerLevel are read-only from users collection, not stored here
  final int coins;
  final int playerLevel;

  RoomSaveState({
    required this.userId,
    required this.inventory,
    required this.rooms,
    required this.activeRoomIndex,
    required this.coins,
    required this.playerLevel,
  });

  factory RoomSaveState.initial(String userId, {int coins = 0, int playerLevel = 1}) =>
      RoomSaveState(
        userId: userId,
        inventory: const [],
        rooms: [
          RoomDefinition(
            id: 'room_1',
            name: 'Room 1',
            background: RoomAssets.defaultBackground,
            placedItems: const [],
          ),
        ],
        activeRoomIndex: 0,
        coins: coins,           // ✅ comes from users collection
        playerLevel: playerLevel, // ✅ comes from users collection
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
    Map<String, dynamic> userData, // ✅ now receives users collection data
  ) {
    final rawRooms = roomData['rooms'] is List ? roomData['rooms'] as List : null;
    final legacyItems = roomData['placedItems'] is List
        ? roomData['placedItems'] as List
        : const [];

    final parsedRooms = rawRooms == null || rawRooms.isEmpty
        ? [
            RoomDefinition(
              id: 'room_1',
              name: 'Room 1',
              background: RoomAssets.defaultBackground,
              placedItems: legacyItems
                  .whereType<Map>()
                  .map((item) => RoomItem.fromMap(Map<String, dynamic>.from(item)))
                  .toList(),
            ),
          ]
        : rawRooms
            .whereType<Map>()
            .toList()
            .asMap()
            .entries
            .map((entry) => RoomDefinition.fromMap(
                  Map<String, dynamic>.from(entry.value),
                  entry.key,
                ))
            .toList();

    final rooms = parsedRooms.isEmpty
        ? [
            RoomDefinition(
              id: 'room_1',
              name: 'Room 1',
              background: RoomAssets.defaultBackground,
              placedItems: const [],
            ),
          ]
        : parsedRooms;

    final active = ((roomData['activeRoomIndex'] ?? 0) as num).toInt();

    return RoomSaveState(
      userId: userId,
      inventory: List<String>.from(roomData['inventory'] ?? const []),
      rooms: rooms,
      activeRoomIndex: active.clamp(0, rooms.length - 1).toInt(),
      coins: ((userData['coins'] ?? 0) as num).toInt(),           // ✅ from users
      playerLevel: ((userData['level'] ?? 1) as num).toInt(),     // ✅ from users
    );
  }

  RoomSaveState copyWith({
    List<String>? inventory,
    List<RoomDefinition>? rooms,
    int? activeRoomIndex,
    int? coins,
    int? playerLevel,
  }) {
    return RoomSaveState(
      userId: userId,
      inventory: inventory ?? this.inventory,
      rooms: rooms ?? this.rooms,
      activeRoomIndex: activeRoomIndex ?? this.activeRoomIndex,
      coins: coins ?? this.coins,
      playerLevel: playerLevel ?? this.playerLevel,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'inventory': inventory,
        'rooms': rooms.map((room) => room.toMap()).toList(),
        'activeRoomIndex': activeRoomIndex,
        // ✅ coins and playerLevel are NOT saved here, they belong to users collection
        'updatedAt': FieldValue.serverTimestamp(),
      };
}