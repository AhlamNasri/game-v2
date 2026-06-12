import 'dart:ui' show Offset;

enum ClothingCategory { dresses, shoes, pants, shirts, accessories, hair }

extension ClothingCategoryLabel on ClothingCategory {
  /// Player-facing name used on rails, chips and headers.
  String get label {
    switch (this) {
      case ClothingCategory.dresses:
        return 'Outfits';
      case ClothingCategory.shoes:
        return 'Shoes';
      case ClothingCategory.pants:
        return 'Bottoms';
      case ClothingCategory.shirts:
        return 'Tops';
      case ClothingCategory.accessories:
        return 'Accessories';
      case ClothingCategory.hair:
        return 'Hair';
    }
  }

  /// Kawaii emoji glyph shown on the wardrobe category rail.
  String get emoji {
    switch (this) {
      case ClothingCategory.dresses:
        return '👗';
      case ClothingCategory.shoes:
        return '👟';
      case ClothingCategory.pants:
        return '👖';
      case ClothingCategory.shirts:
        return '👚';
      case ClothingCategory.accessories:
        return '🎀';
      case ClothingCategory.hair:
        return '💇‍♀️';
    }
  }
}

/// How a single PNG layer is placed inside the doll canvas.
///
/// Every measurement is a fraction of the preview frame, so the same spec
/// renders identically at any size. Most "fit" garments are pre-positioned on
/// a full-body transparent canvas and therefore use [fullCanvas]; only a few
/// head-region pieces (e.g. headphones) need a custom box.
class LayerSpec {
  /// Horizontal anchor of the layer's centre (0 = left, 1 = right).
  final double centerX;

  /// Layer width as a fraction of the frame width.
  final double widthFactor;

  /// Layer height as a fraction of the frame height.
  final double heightFactor;

  /// Top offset as a fraction of the frame height (may be negative).
  final double topFactor;

  const LayerSpec({
    this.centerX = 0.5,
    this.widthFactor = 1.34,
    this.heightFactor = 1.0,
    this.topFactor = 0.0,
  });

  /// Standard full-body overlay — matches the body silhouette.
  static const fullCanvas = LayerSpec();
}

/// A wearable catalogue entry.
///
/// [assetPath] is the layered "fit" PNG drawn on the doll; [thumbPath] is an
/// optional flat-lay image used for the wardrobe tile (falls back to the fit
/// asset). [layer] drives placement in the renderer — no more per-asset string
/// matching.
class ClothingItem {
  final String id;
  final String name;
  final ClothingCategory category;
  final String assetPath;
  final String gender;
  final String? thumbPath;
  final LayerSpec layer;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    this.gender = 'all',
    this.thumbPath,
    this.layer = LayerSpec.fullCanvas,
  });

  /// Image shown on a wardrobe tile.
  String get thumbnail => thumbPath ?? assetPath;
}

/// User-applied transform on top of a [LayerSpec] baseline.
///
/// All three values are deltas from the item's default position.
/// Stored in [CharacterCustomization.transforms] — ephemeral (not persisted
/// to Firestore so there is no Firestore schema change required).
class ItemTransform {
  final Offset offset;   // pixel delta from LayerSpec centre
  final double scale;    // multiplicative: 1.0 = no change
  final double rotation; // radians

  const ItemTransform({
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  ItemTransform copyWith({Offset? offset, double? scale, double? rotation}) {
    return ItemTransform(
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}
