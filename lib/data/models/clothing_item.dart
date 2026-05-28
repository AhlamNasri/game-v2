class ClothingItem {
  final String id;
  final String name;
  final String category; // 'top', 'bottom', 'hair', 'shoes', 'accessory'
  final int price;
  final String assetPath;

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.assetPath,
  });

  // Convertir depuis Firestore
  factory ClothingItem.fromMap(Map<String, dynamic> map, String documentId) {
    return ClothingItem(
      id: documentId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'top',
      price: map['price'] ?? 0,
      assetPath: map['assetPath'] ?? '',
    );
  }

  // Convertir pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'assetPath': assetPath,
    };
  }
}