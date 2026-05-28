class FurnitureItem {
  final String id;
  final String name;
  final int price;
  final String assetPath;
  final double positionX; // Position sauvegardée pour la chambre
  final double positionY;

  FurnitureItem({
    required this.id,
    required this.name,
    required this.price,
    required this.assetPath,
    this.positionX = 0.0,
    this.positionY = 0.0,
  });

  factory FurnitureItem.fromMap(Map<String, dynamic> map, String documentId) {
    return FurnitureItem(
      id: documentId,
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
      assetPath: map['assetPath'] ?? '',
      positionX: (map['positionX'] ?? 0.0).toDouble(),
      positionY: (map['positionY'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'assetPath': assetPath,
      'positionX': positionX,
      'positionY': positionY,
    };
  }
}