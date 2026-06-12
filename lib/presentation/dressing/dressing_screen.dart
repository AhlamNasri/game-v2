import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/character_provider.dart';
import '../../application/inventory_provider.dart';
import '../../data/models/clothing_item.dart';
import '../../theme/app_effects.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_widgets.dart';
import 'widgets/dressup_widgets.dart';
import 'widgets/interactive_doll_view.dart';
import 'widgets/wardrobe_panel.dart';

/// The closet — a Y2K/kawaii dress-up studio.
///
/// Landscape: category rail on the left, the doll on an interactive canvas
/// in the centre (drag / pinch / rotate any garment), wardrobe drawer on the
/// right. The active rail category drives which layer responds to gestures.
class DressingScreen extends ConsumerStatefulWidget {
  const DressingScreen({super.key});

  @override
  ConsumerState<DressingScreen> createState() => _DressingScreenState();
}

class _DressingScreenState extends ConsumerState<DressingScreen> {
  ClothingCategory _selected = ClothingCategory.dresses;

  @override
  Widget build(BuildContext context) {
    final character = ref.watch(characterProvider);
    final coins = ref.watch(walletProvider).coins;
    final owned = ref.watch(ownedClothingProvider);
    final isLoadingOwned = ref.watch(userDocProvider).isLoading;

    final categories = railCategoriesFor(character.gender.name);
    final active = categories.contains(_selected)
        ? _selected
        : (categories.isNotEmpty ? categories.first : ClothingCategory.dresses);

    return Scaffold(
      body: Y2kBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              children: [
                _TopBar(
                  coins: coins,
                  onBack: () => context.go('/menu'),
                  onReset: _resetLook,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Category rail ──────────────────────────
                      SizedBox(
                        width: 64,
                        child: CategoryRail(
                          categories: categories,
                          selected: active,
                          onSelected: (c) => setState(() => _selected = c),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ── Interactive doll stage ──────────────────
                      Expanded(
                        flex: 5,
                        child: _DollStage(
                          child: InteractiveDollView(
                            width: 240,
                            selectedCategory: active,
                            onCategorySelected: (c) =>
                                setState(() => _selected = c),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ── Wardrobe drawer ─────────────────────────
                      Expanded(
                        flex: 6,
                        child: HoloCard(
                          padding:
                              const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DrawerHeader(category: active),
                              const SizedBox(height: 8),
                              Expanded(
                                child: WardrobePanel(
                                  category: active,
                                  ownedItemIds: owned,
                                  isLoading: isLoadingOwned,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetLook() {
    ref.read(characterProvider.notifier).resetOutfit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Outfit reset'), duration: Duration(seconds: 2)),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Top bar
// ─────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int coins;
  final VoidCallback onBack;
  final VoidCallback onReset;

  const _TopBar({
    required this.coins,
    required this.onBack,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StickerIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Menu',
          onTap: onBack,
        ),
        const SizedBox(width: 10),
        Shimmer(
          child: Text(
            'Dress Up Studio',
            style: AppTextStyles.heading.copyWith(
              color: Y2kColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Spacer(),
        HoloPill(child: CoinBadge(coins)),
        const SizedBox(width: 10),
        StickerIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Reset outfit',
          onTap: onReset,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Doll stage — holographic card holding the interactive doll
// ─────────────────────────────────────────────────────────

class _DollStage extends StatelessWidget {
  final Widget child;
  const _DollStage({required this.child});

  @override
  Widget build(BuildContext context) {
    return HoloCard(
      padding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: const Alignment(0, 0.86),
            child: Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: Y2kColors.purple.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          PulseGlow(
            color: Y2kColors.pink,
            borderRadius: BorderRadius.circular(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Drawer header
// ─────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final ClothingCategory category;
  const _DrawerHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(category.emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          category.label,
          style: AppTextStyles.subheading.copyWith(
            color: Y2kColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        const Text(
          'tap to wear • tap again to remove',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Y2kColors.inkSoft,
          ),
        ),
      ],
    );
  }
}
