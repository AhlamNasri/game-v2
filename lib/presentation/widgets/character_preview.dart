import 'package:flutter/material.dart';

import '../../data/models/character_customization.dart';
import '../../data/models/clothing_item.dart';

/// The one and only doll renderer.
///
/// Stacks the body, worn garments, hair and accessory as positioned PNG
/// layers. Placement is fully data-driven: each [ClothingItem] carries its own
/// [LayerSpec], so adding art never means editing this file. Wrapped in a
/// [RepaintBoundary] so the competition pipeline can snapshot it to PNG.
class CharacterPreview extends StatelessWidget {
  final CharacterCustomization character;
  final double width;
  final double? height;

  const CharacterPreview({
    super.key,
    required this.character,
    this.width = 260,
    this.height,
  });

  /// Bottom-to-top paint order of the body slots. Dresses sit lowest so a
  /// top/skirt combo layers correctly above them.
  static const _paintOrder = [
    ClothingCategory.dresses,
    ClothingCategory.pants,
    ClothingCategory.shirts,
    ClothingCategory.shoes,
  ];

  @override
  Widget build(BuildContext context) {
    final accessory = character.outfit[ClothingCategory.accessories];

    return SizedBox(
      width: width,
      height: height ?? width * 1.32,
      child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _CharacterLayer(
              assetPath: character.bodyAsset,
              spec: LayerSpec.fullCanvas,
            ),
            for (final category in _paintOrder)
              if (character.outfit[category] != null)
                _CharacterLayer(
                  assetPath: character.outfit[category]!.assetPath,
                  spec: character.outfit[category]!.layer,
                ),
            if (character.hairAsset.isNotEmpty)
              _CharacterLayer(
                assetPath: character.headHairAsset,
                spec: character.hairLayerSpec,
                transform: character.hairTransform,
              ),
            if (accessory != null)
              _CharacterLayer(
                assetPath: accessory.assetPath,
                spec: accessory.layer,
              ),
          ],
        ),
    );
  }
}

class _CharacterLayer extends StatelessWidget {
  final String assetPath;
  final LayerSpec spec;
  final ItemTransform? transform;

  const _CharacterLayer({
    required this.assetPath,
    required this.spec,
    this.transform,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final frameW = constraints.maxWidth;
          final frameH = constraints.maxHeight;
          final layerW = frameW * spec.widthFactor;
          final layerH = frameH * spec.heightFactor;
          final t = transform;

          if (t == null || (t.offset == Offset.zero && t.scale == 1.0 && t.rotation == 0.0)) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: frameW * spec.centerX - layerW / 2,
                  top: frameH * spec.topFactor,
                  width: layerW,
                  height: layerH,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          }

          final scaledW = layerW * t.scale;
          final scaledH = layerH * t.scale;
          final baseCx = frameW * spec.centerX;
          final baseCy = frameH * spec.topFactor + layerH / 2;
          final left = baseCx + t.offset.dx - scaledW / 2;
          final top = baseCy + t.offset.dy - scaledH / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: left,
                top: top,
                width: scaledW,
                height: scaledH,
                child: Transform.rotate(
                  angle: t.rotation,
                  alignment: Alignment.center,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
