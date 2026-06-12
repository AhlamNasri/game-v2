import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_room_girls/application/inventory_provider.dart';
import 'package:fashion_room_girls/data/repositories/furniture_catalog.dart';
import 'package:fashion_room_girls/theme/app_effects.dart';
import 'package:fashion_room_girls/theme/app_theme.dart';
import 'package:fashion_room_girls/theme/app_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────
//  Clothing shop model (wired to ClothingItem IDs)
// ─────────────────────────────────────────────────────────

class ShopItem {
  final String id;
  final String name;
  final int price;
  final String imagePath;
  final String clothingItemId;
  final int levelRequired;

  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.clothingItemId,
    required this.levelRequired,
  });

  ItemRarity get rarity => ItemRarityStyle.fromPrice(price);
}

const _clothingCatalog = [
  // ── Outfits ──────────────────────────────────────────────────────────────
  ShopItem(
    id: 'casual_hoodie_skirt',
    name: 'Casual Hoodie',
    price: 180,
    imagePath: 'assets/characters/clothes/dresses/casual.png',
    clothingItemId: 'casual_hoodie_skirt',
    levelRequired: 1,
  ),
  ShopItem(
    id: 'gothic_dress',
    name: 'Gothic Dress',
    price: 320,
    imagePath: 'assets/characters/clothes/dresses/dress.png',
    clothingItemId: 'gothic_dress',
    levelRequired: 2,
  ),
  ShopItem(
    id: 'school_uniform_new',
    name: 'School Uniform',
    price: 240,
    imagePath: 'assets/characters/clothes/dresses/school.png',
    clothingItemId: 'school_uniform_new',
    levelRequired: 1,
  ),

  // ── Bottoms ───────────────────────────────────────────────────────────────
  ShopItem(
    id: 'plaid_skirt',
    name: 'Plaid Skirt',
    price: 180,
    imagePath: 'assets/characters/clothes/dresses/plaid_skirt_fit.png',
    clothingItemId: 'plaid_skirt',
    levelRequired: 1,
  ),
  ShopItem(
    id: 'skirt_long',
    name: 'Long Skirt',
    price: 150,
    imagePath: 'assets/characters/clothes/dresses/skirt_long.png',
    clothingItemId: 'skirt_long',
    levelRequired: 1,
  ),
  ShopItem(
    id: 'plaid_trousers',
    name: 'Plaid Trousers',
    price: 200,
    imagePath: 'assets/characters/clothes/pants/plaid_trousers.png',
    clothingItemId: 'plaid_trousers',
    levelRequired: 1,
  ),

  // ── Tops ─────────────────────────────────────────────────────────────────
  ShopItem(
    id: 'field_jacket',
    name: 'Field Jacket',
    price: 280,
    imagePath: 'assets/characters/clothes/shirts/field_jacket.png',
    clothingItemId: 'field_jacket',
    levelRequired: 2,
  ),
  ShopItem(
    id: 'jacket_leather_black',
    name: 'Leather Jacket',
    price: 350,
    imagePath: 'assets/characters/clothes/shirts/jacket_leather_black_fit.png',
    clothingItemId: 'jacket_leather_black',
    levelRequired: 2,
  ),

  // ── Shoes ─────────────────────────────────────────────────────────────────
  ShopItem(
    id: 'boots_black',
    name: 'Black Boots',
    price: 160,
    imagePath: 'assets/characters/clothes/shoes/boots_black_fit.png',
    clothingItemId: 'boots_black',
    levelRequired: 1,
  ),
  ShopItem(
    id: 'lace_up_boots',
    name: 'Lace-Up Boots',
    price: 220,
    imagePath: 'assets/characters/clothes/shoes/lace_up_boots.png',
    clothingItemId: 'lace_up_boots',
    levelRequired: 1,
  ),

  // ── Accessories ───────────────────────────────────────────────────────────
  ShopItem(
    id: 'glasses_round',
    name: 'Round Glasses',
    price: 100,
    imagePath: 'assets/characters/clothes/accessories/glasses_round.png',
    clothingItemId: 'glasses_round',
    levelRequired: 1,
  ),
  ShopItem(
    id: 'acc_headphones_black',
    name: 'Headphones',
    price: 200,
    imagePath:
        'assets/characters/clothes/accessories/acc_headphones_black_fit.png',
    clothingItemId: 'acc_headphones_black',
    levelRequired: 2,
  ),
  ShopItem(
    id: 'acc_glasses_red',
    name: 'Red Glasses',
    price: 120,
    imagePath: 'assets/characters/clothes/accessories/acc_glasses_red_fit.png',
    clothingItemId: 'acc_glasses_red',
    levelRequired: 1,
  ),
];

// ─────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  FurnitureCategory _furnitureCategory = FurnitureCategory.beds;
  bool _isBuying = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── purchases ─────────────────────────────────────────

  Future<void> _buyClothing(ShopItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'boughtItems': FieldValue.arrayUnion([item.clothingItemId]),
      'coins': FieldValue.increment(-item.price),
    });
  }

  Future<void> _buyFurniture(FurnitureShopItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in to shop');

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final roomRef =
        FirebaseFirestore.instance.collection('user_rooms').doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final roomSnap = await tx.get(roomRef);
      final coins = (userSnap.data()?['coins'] ?? 0) as int;
      final inventory =
          {...?(roomSnap.data()?['inventory'] as List?)?.cast<String>()};

      if (inventory.contains(item.id)) throw Exception('Already owned');
      if (coins < item.price) throw Exception('Not enough coins');

      tx.update(userRef, {'coins': FieldValue.increment(-item.price)});
      tx.set(roomRef, {
        'inventory': FieldValue.arrayUnion([item.id]),
      }, SetOptions(merge: true));
    });
  }

  // ── buy flow (shared confirm dialog) ──────────────────

  Future<void> _confirmPurchase({
    required String name,
    required String imagePath,
    required int price,
    required int coins,
    required ItemRarity rarity,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PurchaseDialog(
        name: name,
        imagePath: imagePath,
        price: price,
        coins: coins,
        rarity: rarity,
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isBuying = true);
    try {
      await onConfirm();
      if (mounted) {
        showFloatingReward(context, text: '$name unlocked!',
            color: rarity.color);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Not enough')) return 'Not enough coins';
    if (msg.contains('Already owned')) return 'You already own this';
    if (msg.contains('sign in')) return 'Please sign in to shop';
    return 'Something went wrong. Try again.';
  }

  void _onClothingTap(ShopItem item, int coins, int level, bool owned) {
    if (owned) return;
    if (level < item.levelRequired) return;
    if (coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins 😢')),
      );
      return;
    }
    _confirmPurchase(
      name: item.name,
      imagePath: item.imagePath,
      price: item.price,
      coins: coins,
      rarity: item.rarity,
      onConfirm: () => _buyClothing(item),
    );
  }

  void _onFurnitureTap(FurnitureShopItem item, int coins, bool owned) {
    if (owned) return;
    if (coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins 😢')),
      );
      return;
    }
    _confirmPurchase(
      name: item.name,
      imagePath: item.asset,
      price: item.price,
      coins: coins,
      rarity: item.rarity,
      onConfirm: () => _buyFurniture(item),
    );
  }

  // ── build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(userDocProvider).isLoading;
    final wallet = ref.watch(walletProvider);
    final ownedClothing = ref.watch(ownedClothingProvider);
    final ownedFurniture = ref.watch(ownedFurnitureProvider).maybeWhen(
          data: (s) => s,
          orElse: () => <String>{},
        );

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: AbsorbPointer(
        absorbing: _isBuying,
        child: Column(
          children: [
            _ShopHeader(coins: wallet.coins, isLoading: isLoading),
            Expanded(
              child: AppPageBackground(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      children: [
                        _CategoryTabs(controller: _tabController),
                        const SizedBox(height: 10),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _ClothingTab(
                                items: _clothingCatalog,
                                coins: wallet.coins,
                                level: wallet.level,
                                owned: ownedClothing,
                                onTap: _onClothingTap,
                              ),
                              _FurnitureTab(
                                selected: _furnitureCategory,
                                onCategory: (c) =>
                                    setState(() => _furnitureCategory = c),
                                coins: wallet.coins,
                                owned: ownedFurniture,
                                onTap: _onFurnitureTap,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────────────────

class _ShopHeader extends StatelessWidget {
  final int coins;
  final bool isLoading;
  const _ShopHeader({required this.coins, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.go('/menu'),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: 'Menu',
              ),
              Expanded(
                child: Text(
                  'Shop',
                  style: AppTextStyles.heading.copyWith(color: Colors.white),
                ),
              ),
              isLoading
                  ? const Padding(
                      padding: EdgeInsets.only(right: 18),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: CoinBadge(coins),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Tab bar
// ─────────────────────────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  final TabController controller;
  const _CategoryTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textLight,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        indicator: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent]),
          borderRadius: BorderRadius.circular(20),
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checkroom_rounded, size: 18),
                SizedBox(width: 6),
                Text('Clothes'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.weekend_rounded, size: 18),
                SizedBox(width: 6),
                Text('Furniture'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Clothing tab
// ─────────────────────────────────────────────────────────

class _ClothingTab extends StatelessWidget {
  final List<ShopItem> items;
  final int coins;
  final int level;
  final Set<String> owned;
  final void Function(ShopItem, int coins, int level, bool owned) onTap;

  const _ClothingTab({
    required this.items,
    required this.coins,
    required this.level,
    required this.owned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 168,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isOwned = owned.contains(item.clothingItemId);
        final isLocked = level < item.levelRequired;
        return _ShopCard(
          name: item.name,
          imagePath: item.imagePath,
          price: item.price,
          rarity: item.rarity,
          isOwned: isOwned,
          lockedLabel: isLocked ? 'Lv.${item.levelRequired}' : null,
          onTap: () => onTap(item, coins, level, isOwned),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Furniture tab — built dynamically from RoomAssets
// ─────────────────────────────────────────────────────────

class _FurnitureTab extends StatelessWidget {
  final FurnitureCategory selected;
  final ValueChanged<FurnitureCategory> onCategory;
  final int coins;
  final Set<String> owned;
  final void Function(FurnitureShopItem, int coins, bool owned) onTap;

  const _FurnitureTab({
    required this.selected,
    required this.onCategory,
    required this.coins,
    required this.owned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = FurnitureCatalog.byCategory;
    final items = grouped[selected] ?? const [];

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: FurnitureCategory.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = FurnitureCategory.values[i];
              return _SubCategoryChip(
                label: cat.label,
                icon: cat.icon,
                selected: cat == selected,
                onTap: () => onCategory(cat),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 168,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) {
              final item = items[i];
              final isOwned = owned.contains(item.id);
              return _ShopCard(
                name: item.name,
                imagePath: item.asset,
                price: item.price,
                rarity: item.rarity,
                isOwned: isOwned,
                lockedLabel: null,
                onTap: () => onTap(item, coins, isOwned),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubCategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SubCategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.accent : const Color(0xFFF0E0EA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textMid),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : AppColors.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Shared shop card (clothing + furniture)
// ─────────────────────────────────────────────────────────

class _ShopCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final int price;
  final ItemRarity rarity;
  final bool isOwned;
  final String? lockedLabel;
  final VoidCallback onTap;

  const _ShopCard({
    required this.name,
    required this.imagePath,
    required this.price,
    required this.rarity,
    required this.isOwned,
    required this.lockedLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = lockedLabel != null;
    return TapBounce(
      onTap: isOwned || isLocked ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: rarity.color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: rarity.color.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_not_supported_rounded,
                        size: 36,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '$price',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
            // Rarity ribbon
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: rarity.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rarity.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            // Owned overlay
            if (isOwned)
              _StatusOverlay(
                color: const Color(0xFF63B97D),
                icon: Icons.check_circle_rounded,
                label: 'Owned',
              ),
            // Level-locked overlay
            if (isLocked && !isOwned)
              _StatusOverlay(
                color: Colors.black.withValues(alpha: 0.55),
                icon: Icons.lock_rounded,
                label: '$lockedLabel required',
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusOverlay extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _StatusOverlay({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          color: color,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Purchase confirmation dialog
// ─────────────────────────────────────────────────────────

class _PurchaseDialog extends StatelessWidget {
  final String name;
  final String imagePath;
  final int price;
  final int coins;
  final ItemRarity rarity;

  const _PurchaseDialog({
    required this.name,
    required this.imagePath,
    required this.price,
    required this.coins,
    required this.rarity,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = coins - price;
    final affordable = remaining >= 0;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: rarity.color.withValues(alpha: 0.5), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: rarity.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                rarity.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                    Icons.image_not_supported_rounded,
                    size: 48,
                    color: AppColors.textLight),
              ),
            ),
            const SizedBox(height: 8),
            Text(name, style: AppTextStyles.subheading),
            const SizedBox(height: 8),
            Text(
              affordable
                  ? 'Cost 🪙$price  ·  Balance after 🪙$remaining'
                  : 'Cost 🪙$price  ·  You have 🪙$coins',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: affordable ? AppColors.textMid : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: affordable
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Buy'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
