import '../data/room_assets.dart';
import 'room_item.dart';

class RoomDefinition {
  final String id;
  final String name;
  final String background;
  final int unlockCost;
  final List<RoomItem> placedItems;

  RoomDefinition({
    required this.id,
    required this.name,
    required this.background,
    this.unlockCost = 0,
    required List<RoomItem> placedItems,
  }) : placedItems = List<RoomItem>.of(placedItems);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'background': background,
    'unlockCost': unlockCost,
    'placedItems': placedItems.map((item) => item.toMap()).toList(),
  };

  factory RoomDefinition.fromMap(Map<String, dynamic> map, int index) {
    final items = map['placedItems'] is List ? map['placedItems'] as List : [];
    return RoomDefinition(
      id: (map['id'] ?? 'room_${index + 1}').toString(),
      name: (map['name'] ?? 'Room ${index + 1}').toString(),
      background: (map['background'] ?? RoomAssets.defaultBackground)
          .toString(),
      unlockCost: ((map['unlockCost'] ?? 0) as num).toInt(),
      placedItems: items
          .whereType<Map>()
          .map((item) => RoomItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
