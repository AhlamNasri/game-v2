import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/character_provider.dart';
import '../../../data/models/clothing_item.dart';
import '../../../theme/app_effects.dart';
import 'dressup_widgets.dart';

/// Interactive dress-up canvas used in the closet screen.
///
/// Body is a static anchor. Every equipped garment AND the hair layer live in
/// their own freely-transformable layers: one finger drags, two fingers
/// pinch-to-scale or rotate. The active [selectedCategory] drives which slot
/// responds to gestures — including [ClothingCategory.hair].
///
/// Room-decoration-style UX:
///   • Tap the head region of the doll to select the hair slot.
///   • Tap any body region to select the matching clothing slot.
///   • A floating pill toolbar appears above the active item with
///     reset / remove controls (hair shows reset only — it can't be removed).
class InteractiveDollView extends ConsumerStatefulWidget {
  final double width;
  final ClothingCategory? selectedCategory;
  final ValueChanged<ClothingCategory>? onCategorySelected;

  const InteractiveDollView({
    super.key,
    this.width = 240,
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  ConsumerState<InteractiveDollView> createState() =>
      _InteractiveDollViewState();
}

class _InteractiveDollViewState extends ConsumerState<InteractiveDollView> {
  Offset? _startFocal;
  ItemTransform? _startTransform;

  static const _bodySlots = [
    ClothingCategory.dresses,
    ClothingCategory.pants,
    ClothingCategory.shirts,
    ClothingCategory.shoes,
  ];

  @override
  Widget build(BuildContext context) {
    final character = ref.watch(characterProvider);
    final sel = widget.selectedCategory;
    final isHairSelected = sel == ClothingCategory.hair;

    // Hair is always "equipped" (it's always on the character); clothing slots
    // are equipped only when the outfit map contains an item for them.
    final hasEquipped = sel != null &&
        (isHairSelected
            ? character.hairAsset.isNotEmpty
            : character.outfit[sel] != null);

    final sorted = [..._bodySlots]
      ..sort((a, b) => character.zOrderOf(a).compareTo(character.zOrderOf(b)));

    final frameW = widget.width;
    final frameH = widget.width * 1.32;

    final dollLayers = SizedBox(
      width: frameW,
      height: frameH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Body
          _StaticLayer(
            assetPath: character.bodyAsset,
            spec: LayerSpec.fullCanvas,
            frameW: frameW,
            frameH: frameH,
          ),
          // Clothing layers (z-ordered)
          for (final category in sorted)
            if (character.outfit[category] != null)
              _TransformLayer(
                key: ValueKey(category),
                item: character.outfit[category]!,
                transform:
                    character.transforms[category] ?? const ItemTransform(),
                frameW: frameW,
                frameH: frameH,
              ),
          // Hair — fully interactive, same gesture system as clothing
          if (character.hairAsset.isNotEmpty)
            _HairLayer(
              assetPath: character.headHairAsset,
              spec: character.hairLayerSpec,
              transform: character.hairTransform,
              frameW: frameW,
              frameH: frameH,
            ),
          // Accessory (above hair)
          if (character.outfit[ClothingCategory.accessories] != null)
            _TransformLayer(
              key: const ValueKey(ClothingCategory.accessories),
              item: character.outfit[ClothingCategory.accessories]!,
              transform:
                  character.transforms[ClothingCategory.accessories] ??
                      const ItemTransform(),
              frameW: frameW,
              frameH: frameH,
            ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (d) => _handleTap(d),
      onScaleStart: hasEquipped ? _onScaleStart : null,
      onScaleUpdate: hasEquipped ? _onScaleUpdate : null,
      onScaleEnd: hasEquipped ? _onScaleEnd : null,
      child: SizedBox(
        width: frameW,
        height: frameH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            dollLayers,

            // ── Hair selection indicators ─────────────────────────────────
            if (isHairSelected && character.hairAsset.isNotEmpty) ...[
              _HairSelectionDot(
                spec: character.hairLayerSpec,
                transform: character.hairTransform,
                frameW: frameW,
                frameH: frameH,
              ),
              _HairToolbar(
                spec: character.hairLayerSpec,
                transform: character.hairTransform,
                frameW: frameW,
                frameH: frameH,
                onReset: () =>
                    ref.read(characterProvider.notifier).resetHairTransform(),
              ),
            ],

            // ── Clothing selection indicators ─────────────────────────────
            if (!isHairSelected && hasEquipped) ...[
              _SelectionDot(
                item: character.outfit[sel]!,
                transform:
                    character.transforms[sel] ?? const ItemTransform(),
                frameW: frameW,
                frameH: frameH,
              ),
              _DollItemToolbar(
                category: sel,
                item: character.outfit[sel]!,
                transform:
                    character.transforms[sel] ?? const ItemTransform(),
                frameW: frameW,
                frameH: frameH,
                onRaise: () =>
                    ref.read(characterProvider.notifier).raiseLayer(sel),
                onLower: () =>
                    ref.read(characterProvider.notifier).lowerLayer(sel),
                onReset: () =>
                    ref.read(characterProvider.notifier).resetTransform(sel),
                onUnequip: () =>
                    ref.read(characterProvider.notifier).unequip(sel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    final character = ref.read(characterProvider);
    final frameH = widget.width * 1.32;
    final relY = details.localPosition.dy / frameH;
    final outfit = character.outfit;

    ClothingCategory? hit;
    // Head region — prefer accessories if equipped, fall back to hair
    if (relY < 0.25) {
      if (outfit.containsKey(ClothingCategory.accessories)) {
        hit = ClothingCategory.accessories;
      } else if (character.hairAsset.isNotEmpty) {
        hit = ClothingCategory.hair;
      }
    } else if (relY < 0.62) {
      if (outfit.containsKey(ClothingCategory.dresses)) {
        hit = ClothingCategory.dresses;
      } else if (outfit.containsKey(ClothingCategory.shirts)) {
        hit = ClothingCategory.shirts;
      }
    } else if (relY < 0.82 && outfit.containsKey(ClothingCategory.pants)) {
      hit = ClothingCategory.pants;
    } else if (outfit.containsKey(ClothingCategory.shoes)) {
      hit = ClothingCategory.shoes;
    }

    if (hit != null && hit != widget.selectedCategory) {
      widget.onCategorySelected?.call(hit);
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    final sel = widget.selectedCategory;
    if (sel == null) return;
    _startFocal = details.focalPoint;
    final character = ref.read(characterProvider);
    _startTransform = sel == ClothingCategory.hair
        ? character.hairTransform
        : character.transforms[sel] ?? const ItemTransform();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final sel = widget.selectedCategory;
    if (sel == null || _startFocal == null || _startTransform == null) return;
    final delta = details.focalPoint - _startFocal!;
    final newTransform = ItemTransform(
      offset: _startTransform!.offset + delta,
      scale: (_startTransform!.scale * details.scale).clamp(0.15, 5.0),
      rotation: _startTransform!.rotation + details.rotation,
    );
    if (sel == ClothingCategory.hair) {
      ref.read(characterProvider.notifier).updateHairTransform(newTransform);
    } else {
      ref.read(characterProvider.notifier).updateTransform(sel, newTransform);
    }
  }

  void _onScaleEnd(ScaleEndDetails _) {
    _startFocal = null;
    _startTransform = null;
  }
}

// ─────────────────────────────────────────────────────────
//  Static layer — body only (not interactive)
// ─────────────────────────────────────────────────────────

class _StaticLayer extends StatelessWidget {
  final String assetPath;
  final LayerSpec spec;
  final double frameW;
  final double frameH;

  const _StaticLayer({
    required this.assetPath,
    required this.spec,
    required this.frameW,
    required this.frameH,
  });

  @override
  Widget build(BuildContext context) {
    final layerW = frameW * spec.widthFactor;
    final layerH = frameH * spec.heightFactor;
    return Positioned(
      left: frameW * spec.centerX - layerW / 2,
      top: frameH * spec.topFactor,
      width: layerW,
      height: layerH,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, e, s) => const SizedBox.shrink(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Hair layer — same as _TransformLayer but driven by
//  LayerSpec + hairTransform instead of a ClothingItem
// ─────────────────────────────────────────────────────────

class _HairLayer extends StatelessWidget {
  final String assetPath;
  final LayerSpec spec;
  final ItemTransform transform;
  final double frameW;
  final double frameH;

  const _HairLayer({
    required this.assetPath,
    required this.spec,
    required this.transform,
    required this.frameW,
    required this.frameH,
  });

  @override
  Widget build(BuildContext context) {
    final layerW = frameW * spec.widthFactor;
    final layerH = frameH * spec.heightFactor;
    final baseCx = frameW * spec.centerX;
    final baseCy = frameH * spec.topFactor + layerH / 2;
    final scaledW = layerW * transform.scale;
    final scaledH = layerH * transform.scale;
    final left = baseCx + transform.offset.dx - scaledW / 2;
    final top = baseCy + transform.offset.dy - scaledH / 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: left,
          top: top,
          width: scaledW,
          height: scaledH,
          child: Transform.rotate(
            angle: transform.rotation,
            alignment: Alignment.center,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, e, s) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Transformable clothing layer
// ─────────────────────────────────────────────────────────

class _TransformLayer extends StatelessWidget {
  final ClothingItem item;
  final ItemTransform transform;
  final double frameW;
  final double frameH;

  const _TransformLayer({
    super.key,
    required this.item,
    required this.transform,
    required this.frameW,
    required this.frameH,
  });

  @override
  Widget build(BuildContext context) {
    final spec = item.layer;
    final layerW = frameW * spec.widthFactor;
    final layerH = frameH * spec.heightFactor;

    final baseCx = frameW * spec.centerX;
    final baseCy = frameH * spec.topFactor + layerH / 2;

    final scaledW = layerW * transform.scale;
    final scaledH = layerH * transform.scale;
    final left = baseCx + transform.offset.dx - scaledW / 2;
    final top = baseCy + transform.offset.dy - scaledH / 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: left,
          top: top,
          width: scaledW,
          height: scaledH,
          child: Transform.rotate(
            angle: transform.rotation,
            alignment: Alignment.center,
            child: Image.asset(
              item.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, e, s) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Selection dot — small indicator at the active item centre
// ─────────────────────────────────────────────────────────

class _SelectionDot extends StatelessWidget {
  final ClothingItem item;
  final ItemTransform transform;
  final double frameW;
  final double frameH;

  const _SelectionDot({
    required this.item,
    required this.transform,
    required this.frameW,
    required this.frameH,
  });

  @override
  Widget build(BuildContext context) {
    final spec = item.layer;
    final layerH = frameH * spec.heightFactor;
    final cx = frameW * spec.centerX + transform.offset.dx;
    final cy = frameH * spec.topFactor +
        layerH * transform.scale / 2 +
        transform.offset.dy;

    const size = 24.0;
    return Positioned(
      left: cx - size / 2,
      top: cy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: Y2kColors.pink.withValues(alpha: 0.22),
            shape: BoxShape.circle,
            border: Border.all(
              color: Y2kColors.pink.withValues(alpha: 0.75),
              width: 2,
            ),
          ),
          child: const Icon(Icons.open_with_rounded, size: 12, color: Y2kColors.pink),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Hair selection dot
// ─────────────────────────────────────────────────────────

class _HairSelectionDot extends StatelessWidget {
  final LayerSpec spec;
  final ItemTransform transform;
  final double frameW;
  final double frameH;

  const _HairSelectionDot({
    required this.spec,
    required this.transform,
    required this.frameW,
    required this.frameH,
  });

  @override
  Widget build(BuildContext context) {
    final layerH = frameH * spec.heightFactor;
    final cx = frameW * spec.centerX + transform.offset.dx;
    final cy = frameH * spec.topFactor +
        layerH * transform.scale / 2 +
        transform.offset.dy;

    const size = 24.0;
    return Positioned(
      left: cx - size / 2,
      top: cy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: Y2kColors.purple.withValues(alpha: 0.22),
            shape: BoxShape.circle,
            border: Border.all(
              color: Y2kColors.purple.withValues(alpha: 0.75),
              width: 2,
            ),
          ),
          child: const Icon(Icons.open_with_rounded, size: 12, color: Y2kColors.purple),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Hair toolbar — reset only (hair can't be removed)
// ─────────────────────────────────────────────────────────

class _HairToolbar extends StatelessWidget {
  final LayerSpec spec;
  final ItemTransform transform;
  final double frameW;
  final double frameH;
  final VoidCallback onReset;

  const _HairToolbar({
    required this.spec,
    required this.transform,
    required this.frameW,
    required this.frameH,
    required this.onReset,
  });

  static const _w = 56.0;
  static const _h = 36.0;
  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final itemTopY = frameH * spec.topFactor + transform.offset.dy;
    final rawY = itemTopY - _h - _gap;
    final toolbarY = rawY.clamp(4.0, frameH - _h - 4.0);
    final toolbarX = (frameW - _w) / 2;

    return Positioned(
      left: toolbarX,
      top: toolbarY,
      width: _w,
      height: _h,
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        shape: const StadiumBorder(),
        elevation: 6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Y2kColors.purple.withValues(alpha: 0.36)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolBtn(
                icon: Icons.refresh_rounded,
                color: Y2kColors.blue,
                tooltip: 'Reset hair',
                onTap: onReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Floating toolbar — room-style pill of contextual controls
// ─────────────────────────────────────────────────────────

class _DollItemToolbar extends StatelessWidget {
  final ClothingCategory category;
  final ClothingItem item;
  final ItemTransform transform;
  final double frameW;
  final double frameH;
  final VoidCallback onRaise;
  final VoidCallback onLower;
  final VoidCallback onReset;
  final VoidCallback onUnequip;

  const _DollItemToolbar({
    required this.category,
    required this.item,
    required this.transform,
    required this.frameW,
    required this.frameH,
    required this.onRaise,
    required this.onLower,
    required this.onReset,
    required this.onUnequip,
  });

  static const _w = 168.0;
  static const _h = 36.0;
  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final itemTopY = frameH * item.layer.topFactor + transform.offset.dy;
    final rawY = itemTopY - _h - _gap;
    final toolbarY = rawY.clamp(4.0, frameH - _h - 4.0);
    final toolbarX = (frameW - _w) / 2;

    return Positioned(
      left: toolbarX,
      top: toolbarY,
      width: _w,
      height: _h,
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        shape: const StadiumBorder(),
        elevation: 6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Y2kColors.pink.withValues(alpha: 0.36)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolBtn(
                icon: Icons.flip_to_back_rounded,
                color: Y2kColors.purple,
                tooltip: 'Send Back',
                onTap: onLower,
              ),
              _ToolBtn(
                icon: Icons.flip_to_front_rounded,
                color: Y2kColors.purple,
                tooltip: 'Bring Front',
                onTap: onRaise,
              ),
              _ToolBtn(
                icon: Icons.refresh_rounded,
                color: Y2kColors.blue,
                tooltip: 'Reset',
                onTap: onReset,
              ),
              _ToolBtn(
                icon: Icons.close_rounded,
                color: const Color(0xFFFF6B8A),
                tooltip: 'Remove',
                onTap: onUnequip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}
