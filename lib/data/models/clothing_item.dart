enum ClothingCategory { dresses, shoes, pants, shirts, accessories, hair }

extension ClothingCategoryLabel on ClothingCategory {
  String get label {
    switch (this) {
      case ClothingCategory.dresses:
        return 'Tenues';
      case ClothingCategory.shoes:
        return 'Chaussures';
      case ClothingCategory.pants:
        return 'Pantalons';
      case ClothingCategory.shirts:
        return 'T-shirts';
      case ClothingCategory.accessories:
        return 'Accessoires';
      case ClothingCategory.hair:
        return 'Cheveux';
    }
  }
}

class ClothingItem {
  final String id;
  final String name;
  final ClothingCategory category;
  final String assetPath;
  final String gender;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    this.gender = 'all',
  });
}
