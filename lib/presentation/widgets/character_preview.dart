import 'package:flutter/material.dart';

import '../../data/models/character_customization.dart';
import '../../data/models/clothing_item.dart';

class CharacterPreview extends StatelessWidget {
  final CharacterCustomization character;
  final double width;
  final double? height;
  final GlobalKey? repaintKey;

  const CharacterPreview({
    super.key,
    required this.character,
    this.width = 260,
    this.height,
    this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    final outfitLayers = [
      ClothingCategory.dresses,
      ClothingCategory.pants,
      ClothingCategory.shirts,
      ClothingCategory.shoes,
    ];
    final accessory = character.outfit[ClothingCategory.accessories];
    final headHairAsset = character.headHairAsset;

    return SizedBox(
      width: width,
      height: height ?? width * 1.32,
      child: RepaintBoundary(
        key: repaintKey,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _CharacterLayer(
              assetPath: character.bodyAsset,
              spec: _CharacterLayerSpec.fullCanvas,
            ),
            for (final category in outfitLayers)
              if (character.outfit[category] != null)
                _CharacterLayer(
                  assetPath: character.outfit[category]!.assetPath,
                  spec: _CharacterLayerSpec.forAsset(
                    character.outfit[category]!.assetPath,
                  ),
                ),
            if (character.hairAsset.isNotEmpty)
              _CharacterLayer(
                assetPath: headHairAsset,
                spec: _CharacterLayerSpec.forAsset(headHairAsset),
              ),
            if (accessory != null)
              _CharacterLayer(
                assetPath: accessory.assetPath,
                spec: _CharacterLayerSpec.forAsset(accessory.assetPath),
              ),
          ],
        ),
      ),
    );
  }
}

class _CharacterLayer extends StatelessWidget {
  final String assetPath;
  final _CharacterLayerSpec spec;

  const _CharacterLayer({
    required this.assetPath,
    required this.spec,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final frameWidth = constraints.maxWidth;
          final frameHeight = constraints.maxHeight;
          final layerWidth = frameWidth * spec.widthFactor;
          final layerHeight = frameHeight * spec.heightFactor;
          final left = frameWidth * spec.centerX - layerWidth / 2;
          final top = frameHeight * spec.topFactor;

          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                width: layerWidth,
                height: layerHeight,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CharacterLayerSpec {
  final double centerX;
  final double widthFactor;
  final double heightFactor;
  final double topFactor;

  const _CharacterLayerSpec({
    required this.centerX,
    required this.widthFactor,
    required this.heightFactor,
    required this.topFactor,
  });

  static const fullCanvas = _CharacterLayerSpec(
    centerX: 0.5,
    widthFactor: 1.34,
    heightFactor: 1.0,
    topFactor: 0.0,
  );

  static _CharacterLayerSpec forAsset(String assetPath) {
    if (assetPath.contains('_head_hair')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 0.56,
        heightFactor: 0.43,
        topFactor: -0.01,
      );
    }

    if (assetPath.contains('hair_short_blue') ||
        assetPath.contains('hair_messy_brown') ||
        assetPath.contains('hair_spiky_black') ||
        assetPath.contains('hair_undercut_blue')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 1.18,
        heightFactor: 0.86,
        topFactor: -0.075,
      );
    }

    if (assetPath.contains('hair_blonde_twintails') ||
        assetPath.contains('hair_bob_brown') ||
        assetPath.contains('hair_twintails_pink') ||
        assetPath.contains('hair_pink_cat_ears')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 1.08,
        heightFactor: 0.78,
        topFactor: -0.025,
      );
    }

    if (assetPath.contains('/hair/')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 1.12,
        heightFactor: 0.82,
        topFactor: -0.03,
      );
    }

    if (assetPath.contains('_fit.')) {
      return fullCanvas;
    }

    if (assetPath.contains('dress_gothic_lolita')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 0.62,
        heightFactor: 0.58,
        topFactor: 0.30,
      );
    }

    if (assetPath.contains('plaid_skirt')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 0.50,
        heightFactor: 0.25,
        topFactor: 0.47,
      );
    }

    if (assetPath.contains('bottom_blue_jeans')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 0.46,
        heightFactor: 0.46,
        topFactor: 0.46,
      );
    }

    if (assetPath.contains('jacket_leather_black')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 0.58,
        heightFactor: 0.37,
        topFactor: 0.27,
      );
    }

    if (assetPath.contains('oversized_sweater')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 0.62,
        heightFactor: 0.36,
        topFactor: 0.28,
      );
    }

    if (assetPath.contains('top_pink_hoodie')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 0.58,
        heightFactor: 0.34,
        topFactor: 0.29,
      );
    }

    if (assetPath.contains('boots_black')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 0.38,
        heightFactor: 0.22,
        topFactor: 0.79,
      );
    }

    if (assetPath.contains('sneakers_white')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 0.42,
        heightFactor: 0.18,
        topFactor: 0.83,
      );
    }

    if (assetPath.contains('glasses_round')) {
      return const _CharacterLayerSpec(
        centerX: 0.5,
        widthFactor: 0.43,
        heightFactor: 0.18,
        topFactor: 0.17,
      );
    }

    return const _CharacterLayerSpec(
      centerX: 0.5,
      widthFactor: 0.50,
      heightFactor: 0.45,
      topFactor: 0.30,
    );
  }
}
