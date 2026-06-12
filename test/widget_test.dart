import 'package:flutter_test/flutter_test.dart';

import 'package:fashion_room_girls/data/models/clothing_item.dart';
import 'package:fashion_room_girls/data/repositories/fashion_catalog.dart';

void main() {
  test('boy outfits do not appear in girl dressing catalog', () {
    final girlDresses = FashionCatalog.byCategory(
      ClothingCategory.dresses,
      'girl',
    ).map((item) => item.assetPath);

    expect(
      girlDresses,
      isNot(
        contains(
          'assets/characters/clothes/dresses/outfit_sporty_tracksuit_fit.png',
        ),
      ),
    );
    expect(
      girlDresses,
      isNot(
        contains(
          'assets/characters/clothes/dresses/outfit_cool_jacket_fit.png',
        ),
      ),
    );
    expect(
      girlDresses,
      isNot(
        contains(
          'assets/characters/clothes/dresses/outfit_wizard_robe_fit.png',
        ),
      ),
    );
  });

  test('boy outfits appear in boy dressing catalog', () {
    final boyDresses = FashionCatalog.byCategory(
      ClothingCategory.dresses,
      'boy',
    ).map((item) => item.assetPath);

    expect(
      boyDresses,
      contains(
        'assets/characters/clothes/dresses/outfit_sporty_tracksuit_fit.png',
      ),
    );
    expect(
      boyDresses,
      contains('assets/characters/clothes/dresses/outfit_cool_jacket_fit.png'),
    );
    expect(
      boyDresses,
      contains('assets/characters/clothes/dresses/outfit_wizard_robe_fit.png'),
    );
  });
}
