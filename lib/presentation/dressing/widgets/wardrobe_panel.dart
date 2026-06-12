import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/character_provider.dart';
import '../../../data/models/character_customization.dart';
import '../../../data/models/clothing_item.dart';
import '../../../data/repositories/fashion_catalog.dart';
import '../../../theme/app_effects.dart';
import '../../widgets/character_preview.dart';
import 'dressup_widgets.dart';

/// Display order of the category rail (hair first, accessories last).
const wardrobeCategoryOrder = [
  ClothingCategory.hair,
  ClothingCategory.shirts,
  ClothingCategory.dresses,
  ClothingCategory.pants,
  ClothingCategory.shoes,
  ClothingCategory.accessories,
];

/// Returns the catalog categories available for [gender], in rail order.
List<ClothingCategory> railCategoriesFor(String gender) {
  final available = FashionCatalog.categoriesFor(gender);
  return wardrobeCategoryOrder.where(available.contains).toList(growable: false);
}

// ─────────────────────────────────────────────────────────
//  Category rail — sticker buttons, vertical or horizontal
// ─────────────────────────────────────────────────────────

class CategoryRail extends StatelessWidget {
  final List<ClothingCategory> categories;
  final ClothingCategory selected;
  final ValueChanged<ClothingCategory> onSelected;
  final Axis axis;

  const CategoryRail({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: axis,
      physics: const BouncingScrollPhysics(),
      padding: axis == Axis.vertical
          ? const EdgeInsets.symmetric(vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 2),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10, height: 10),
      itemBuilder: (context, i) {
        final cat = categories[i];
        return _CategorySticker(
          category: cat,
          selected: cat == selected,
          onTap: () => onSelected(cat),
        );
      },
    );
  }
}

class _CategorySticker extends StatelessWidget {
  final ClothingCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategorySticker({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sticker = TapBounce(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Y2kColors.pink, Y2kColors.purple],
                  )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: (selected ? Y2kColors.pink : Y2kColors.purple)
                    .withValues(alpha: selected ? 0.45 : 0.18),
                blurRadius: selected ? 14 : 7,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 3),
              Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : Y2kColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!selected) return sticker;
    return PulseGlow(
      color: Y2kColors.pink,
      borderRadius: BorderRadius.circular(20),
      child: sticker,
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Wardrobe panel — the item drawer (grid or horizontal strip)
// ─────────────────────────────────────────────────────────

class WardrobePanel extends ConsumerWidget {
  final ClothingCategory category;
  final Set<String> ownedItemIds;
  final bool isLoading;

  /// [Axis.vertical] → wrapped grid (closet). [Axis.horizontal] → single-row
  /// strip (the competition play-zone, where height is scarce).
  final Axis axis;

  const WardrobePanel({
    super.key,
    required this.category,
    required this.ownedItemIds,
    required this.isLoading,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(characterProvider);
    final all = FashionCatalog.byCategory(category, character.gender.name);
    final visibleIds = {...FashionCatalog.starterPack, ...ownedItemIds};
    final unlocked = all.where((i) => visibleIds.contains(i.id)).toList();
    final locked = all.where((i) => !visibleIds.contains(i.id)).toList();
    final hasLocked = locked.isNotEmpty;
    final total = unlocked.length + locked.length + (hasLocked ? 1 : 0);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Y2kColors.pink),
      );
    }
    if (all.isEmpty) {
      return const Center(
        child: Text(
          'Nothing here yet 🌸',
          style: TextStyle(
            color: Y2kColors.inkSoft,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    Widget cardAt(int index) {
      if (index < unlocked.length) {
        final item = unlocked[index];
        final equipped = _isEquipped(character, item);
        return _ItemCard(
          item: item,
          character: character,
          selected: equipped,
          onTap: () {
            final notifier = ref.read(characterProvider.notifier);
            // Toggle: tap an equipped non-hair item to unequip it.
            if (equipped && item.category != ClothingCategory.hair) {
              notifier.unequip(item.category);
            } else {
              notifier.wear(item);
            }
          },
        );
      }
      if (index < unlocked.length + locked.length) {
        final item = locked[index - unlocked.length];
        return _LockedCard(
          item: item,
          onTap: () => _shopHint(context),
        );
      }
      return _ShopLinkCard(onTap: () => context.push('/shop'));
    }

    if (axis == Axis.horizontal) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: total,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => AspectRatio(
          aspectRatio: 0.82,
          child: cardAt(i),
        ),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 124,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: total,
      itemBuilder: (context, i) => cardAt(i),
    );
  }

  bool _isEquipped(CharacterCustomization character, ClothingItem item) {
    if (item.category == ClothingCategory.hair) {
      // Compare style ids directly: 'hair1' or 'hair2'.
      final itemStyle = item.id.endsWith('hair2') ? 'hair2' : 'hair1';
      return character.hairStyle == itemStyle;
    }
    return character.outfit[item.category]?.id == item.id;
  }

  void _shopHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This item is in the shop'),
        action: SnackBarAction(
          label: 'Go to Shop',
          onPressed: () => context.push('/shop'),
        ),
      ),
    );
  }
}

String _hairStyle(String h) {
  if (h.contains('hair2') ||
      h.contains('bob_brown') ||
      h.contains('messy_brown') ||
      h.contains('undercut_blue')) {
    return 'hair2';
  }
  return 'hair1';
}

// ─────────────────────────────────────────────────────────
//  Item cards
// ─────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final ClothingItem item;
  final CharacterCustomization character;
  final bool selected;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.character,
    required this.selected,
    required this.onTap,
  });

  // Hair slots cannot be fully removed from the character (they always have
  // a style), so we show a heart badge. Clothing slots show a ✕ badge that
  // signals "tap again to remove".
  bool get _isHair => item.category == ClothingCategory.hair;

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [Color(0xFFFFE6F6), Color(0xFFF1E6FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? Y2kColors.pink : const Color(0xFFF0E4F0),
                width: selected ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (selected ? Y2kColors.pink : Y2kColors.purple)
                      .withValues(alpha: selected ? 0.30 : 0.10),
                  blurRadius: selected ? 14 : 7,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Column(
              children: [
                Expanded(child: _ItemThumb(item: item, character: character)),
                const SizedBox(height: 2),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Y2kColors.ink : Y2kColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  // Hair: gradient heart — still styled, can't be removed.
                  // Clothing: solid red ✕ — signals "tap to remove".
                  gradient: _isHair
                      ? const LinearGradient(
                          colors: [Y2kColors.pink, Y2kColors.purple],
                        )
                      : null,
                  color: _isHair ? null : const Color(0xFFFF4E7A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  _isHair ? Icons.favorite : Icons.close_rounded,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thumbnail: a small doll-head preview for hair, a flat-lay image otherwise.
class _ItemThumb extends StatelessWidget {
  final ClothingItem item;
  final CharacterCustomization character;

  const _ItemThumb({required this.item, required this.character});

  @override
  Widget build(BuildContext context) {
    if (item.category == ClothingCategory.hair) {
      final hairStyle = _hairStyle(item.assetPath);
      final preview = character.copyWith(hairAsset: hairStyle, outfit: {});
      return FittedBox(
        fit: BoxFit.contain,
        child: CharacterPreview(character: preview, width: 86),
      );
    }
    return Image.asset(
      item.thumbnail,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => const Icon(
        Icons.checkroom_rounded,
        color: Color(0xFFE0D4E0),
        size: 30,
      ),
    );
  }
}

class _LockedCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;

  const _LockedCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: onTap,
      child: Stack(
        children: [
          Opacity(
            opacity: 0.45,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF0E4F0), width: 1.5),
              ),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      item.thumbnail,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.checkroom_rounded,
                        color: Color(0xFFE0D4E0),
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Y2kColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned.fill(
            child: Center(
              child: Text('🔒', style: TextStyle(fontSize: 24)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopLinkCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ShopLinkCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF0FA), Color(0xFFF1E9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Y2kColors.purple.withValues(alpha: 0.4)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🛍️', style: TextStyle(fontSize: 28)),
            SizedBox(height: 6),
            Text(
              'More in\nShop',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Y2kColors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
