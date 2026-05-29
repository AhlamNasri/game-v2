import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/character_provider.dart';
import '../../data/models/clothing_item.dart';
import '../../data/repositories/fashion_catalog.dart';
import '../../data/services/character_capture_service.dart';
import '../widgets/character_preview.dart';

class DressingScreen extends ConsumerStatefulWidget {
  const DressingScreen({super.key});

  @override
  ConsumerState<DressingScreen> createState() => _DressingScreenState();
}

class _DressingScreenState extends ConsumerState<DressingScreen> {
  final _characterCaptureKey = GlobalKey();
  final _captureService = CharacterCaptureService();
  ClothingCategory selectedCategory = ClothingCategory.pants;
  bool _isSavingPhoto = false;

  static const _categoryOrder = [
    ClothingCategory.hair,
    ClothingCategory.shirts,
    ClothingCategory.dresses,
    ClothingCategory.pants,
    ClothingCategory.shoes,
    ClothingCategory.accessories,
  ];

  @override
  Widget build(BuildContext context) {
    final character = ref.watch(characterProvider);
    final screenSize = MediaQuery.sizeOf(context);
    final isWide = screenSize.width >= 760;
    final availableCategories = FashionCatalog.categoriesFor(
      character.gender.name,
    );
    final categories = _categoryOrder
        .where(availableCategories.contains)
        .toList(growable: false);
    var activeCategory = ClothingCategory.pants;
    if (categories.isNotEmpty) {
      activeCategory = categories.contains(selectedCategory)
          ? selectedCategory
          : categories.first;
    }
    final bottomHeight = isWide
        ? screenSize.height.clamp(270.0, 320.0).toDouble()
        : screenSize.height.clamp(320.0, 410.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFFFD9E8),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stageHeight = constraints.maxHeight - bottomHeight - 78;
            final previewHeight = stageHeight.clamp(330.0, 590.0).toDouble();
            final previewWidth = (previewHeight * 0.72)
                .clamp(isWide ? 250.0 : 210.0, isWide ? 390.0 : 290.0)
                .toDouble();

            return Column(
              children: [
                _DressingHeader(
                  onBack: _openCharacterSelection,
                  onReset: _resetLook,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFFF0F8),
                                Color(0xFFF4D9FF),
                                Color(0xFFFFC9DE),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        bottom: bottomHeight + 18,
                        child: Center(
                          child: CharacterPreview(
                            character: character,
                            width: previewWidth,
                            height: previewHeight,
                            repaintKey: _characterCaptureKey,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _DressingPanel(
                          height: bottomHeight,
                          categories: categories,
                          selectedCategory: activeCategory,
                          onPhoto: _captureCharacter,
                          isSavingPhoto: _isSavingPhoto,
                          onCategorySelected: (category) {
                            setState(() => selectedCategory = category);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _resetLook() {
    ref.read(characterProvider.notifier).resetOutfit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tenue remise a zero.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openCharacterSelection() {
    context.go('/character');
  }

  Future<void> _captureCharacter() async {
    if (_isSavingPhoto) {
      return;
    }

    final boundary = _characterCaptureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      return;
    }

    setState(() => _isSavingPhoto = true);

    try {
      final character = ref.read(characterProvider);
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data?.buffer.asUint8List();
      if (!mounted || bytes == null) {
        return;
      }

      await _captureService.saveCapture(bytes: bytes, character: character);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo sauvegardee dans ton compte.'),
          duration: Duration(seconds: 2),
        ),
      );

      await showDialog<void>(
        context: context,
        builder: (_) => _CaptureDialog(bytes: bytes),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de sauvegarder la photo : $error'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingPhoto = false);
      }
    }
  }
}

class _DressingHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onReset;

  const _DressingHeader({required this.onBack, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE777AE), Color(0xFFD285C8)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.checkroom_rounded, color: Colors.white, size: 31),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Habillage',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: onReset,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.22),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureDialog extends StatelessWidget {
  final Uint8List bytes;

  const _CaptureDialog({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(22),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Photo du personnage',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Fermer',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}

class _DressingPanel extends ConsumerWidget {
  final double height;
  final List<ClothingCategory> categories;
  final ClothingCategory selectedCategory;
  final VoidCallback onPhoto;
  final bool isSavingPhoto;
  final ValueChanged<ClothingCategory> onCategorySelected;

  const _DressingPanel({
    required this.height,
    required this.categories,
    required this.selectedCategory,
    required this.onPhoto,
    required this.isSavingPhoto,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(characterProvider);
    final clothes = FashionCatalog.byCategory(
      selectedCategory,
      character.gender.name,
    );

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 28,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFEFA7C1),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 66,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryChip(
                  category: category,
                  selected: category == selectedCategory,
                  onTap: () => onCategorySelected(category),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFFFD6E4)),
          SizedBox(
            height: 132,
            child: clothes.isEmpty
                ? const Center(child: Text('Aucun item disponible.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: clothes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final item = clothes[index];
                      final selected = selectedCategory == ClothingCategory.hair
                          ? _sameHairStyle(character.hairAsset, item.assetPath)
                          : character.outfit[selectedCategory]?.id == item.id;
                      return _ClothingTile(
                        item: item,
                        selected: selected,
                        onTap: () {
                          ref.read(characterProvider.notifier).wear(item);
                        },
                      );
                    },
                  ),
          ),
          const Divider(height: 1, color: Color(0xFFFFD6E4)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 10, 26, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.photo_camera_rounded,
                      title: 'Photo',
                      subtitle: isSavingPhoto
                          ? 'Sauvegarde en cours'
                          : 'Enregistrer pour la competition',
                      color: const Color(0xFFE91E8F),
                      onTap: isSavingPhoto ? null : onPhoto,
                      isLoading: isSavingPhoto,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Style',
                      subtitle: 'Appliquer une tenue',
                      color: const Color(0xFF7E38EA),
                      onTap: () {
                        ref.read(characterProvider.notifier).applyBestStyle();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameHairStyle(String currentHair, String itemHair) {
    return _hairStyle(currentHair) == _hairStyle(itemHair);
  }

  String _hairStyle(String hairAsset) {
    if (hairAsset.contains('hair2') ||
        hairAsset.contains('bob_brown') ||
        hairAsset.contains('messy_brown') ||
        hairAsset.contains('undercut_blue')) {
      return 'hair2';
    }

    return 'hair1';
  }
}

class _CategoryChip extends StatelessWidget {
  final ClothingCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFE0EC) : Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.dressingIcon,
                color: selected
                    ? const Color(0xFFD9166B)
                    : const Color(0xFFB7B3B6),
                size: 23,
              ),
              const SizedBox(width: 8),
              Text(
                category.dressingLabel,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFD9166B)
                      : const Color(0xFFB7B3B6),
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClothingTile extends StatelessWidget {
  final ClothingItem item;
  final bool selected;
  final VoidCallback onTap;

  const _ClothingTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFEEF5) : const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 132,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected ? const Color(0xFFE91E8F) : const Color(0xFFF2F2F2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Image.asset(
                    item.assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.checkroom_rounded,
                      color: Color(0xFFDADADA),
                      size: 34,
                    ),
                  ),
                ),
              ),
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF5F5B60),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 10,
      shadowColor: color.withOpacity(0.35),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? const SizedBox(
                      width: 29,
                      height: 29,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 29),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _DressingCategoryStyle on ClothingCategory {
  String get dressingLabel {
    switch (this) {
      case ClothingCategory.hair:
        return 'Cheveux';
      case ClothingCategory.shirts:
        return 'Haut';
      case ClothingCategory.dresses:
        return 'Tenues';
      case ClothingCategory.pants:
        return 'Bas';
      case ClothingCategory.shoes:
        return 'Chaussures';
      case ClothingCategory.accessories:
        return 'Accessoires';
    }
  }

  IconData get dressingIcon {
    switch (this) {
      case ClothingCategory.hair:
        return Icons.face_retouching_natural_rounded;
      case ClothingCategory.shirts:
        return Icons.checkroom_rounded;
      case ClothingCategory.dresses:
        return Icons.dry_cleaning_rounded;
      case ClothingCategory.pants:
        return Icons.accessibility_new_rounded;
      case ClothingCategory.shoes:
        return Icons.ice_skating_rounded;
      case ClothingCategory.accessories:
        return Icons.auto_awesome_rounded;
    }
  }
}
