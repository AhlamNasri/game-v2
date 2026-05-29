import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room_definition.dart';
import '../models/room_item.dart';
import 'room_assets.dart';

class RoomSaveState {
  final String userId;
  final List<String> inventory;
  final List<RoomDefinition> rooms;
  final int activeRoomIndex;
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

  factory RoomSaveState.initial(String userId) => RoomSaveState(
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
    coins: 2500,
    playerLevel: 5,
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
    playerLevel: 5,
  );

  factory RoomSaveState.fromMap(String userId, Map<String, dynamic> data) {
    final rawRooms = data['rooms'] is List ? data['rooms'] as List : null;
    final legacyItems = data['placedItems'] is List
        ? data['placedItems'] as List
        : const [];
    final parsedRooms = rawRooms == null || rawRooms.isEmpty
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

    final active = ((data['activeRoomIndex'] ?? 0) as num).toInt();
    return RoomSaveState(
      userId: userId,
      inventory: List<String>.from(data['inventory'] ?? const []),
      rooms: rooms,
      activeRoomIndex: active.clamp(0, rooms.length - 1).toInt(),
      coins: ((data['coins'] ?? 0) as num).toInt(),
      playerLevel: ((data['playerLevel'] ?? data['level'] ?? 5) as num).toInt(),
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
    'coins': coins,
    'playerLevel': playerLevel,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
