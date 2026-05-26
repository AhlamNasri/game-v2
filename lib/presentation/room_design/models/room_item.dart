class RoomItem {
  final String name;
  final String asset;
  double x;
  double y;
  double width;
  double rotation;
  int layer;

  RoomItem({
    required this.name,
    required this.asset,
    this.x = 100,
    this.y = 100,
    this.width = 120,
    this.rotation = 0,
    this.layer = 0,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'asset': asset,
    'x': x,
    'y': y,
    'width': width,
    'rotation': rotation,
    'layer': layer,
  };

  factory RoomItem.fromMap(Map<String, dynamic> map) => RoomItem(
    name: (map['name'] ?? 'item').toString(),
    asset: (map['asset'] ?? '').toString(),
    x: ((map['x'] ?? 100) as num).toDouble(),
    y: ((map['y'] ?? 100) as num).toDouble(),
    width: ((map['width'] ?? 120) as num).toDouble(),
    rotation: ((map['rotation'] ?? 0) as num).toDouble(),
    layer: ((map['layer'] ?? 0) as num).toInt(),
  );
}
