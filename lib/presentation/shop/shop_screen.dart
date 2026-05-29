import 'package:flutter/material.dart';

class ShopItem {
  final String name;
  final int price;
  final String imagePath;

  const ShopItem({
    required this.name,
    required this.price,
    required this.imagePath,
  });
}

class ShopCategory {
  final String label;
  final IconData icon;
  final List<ShopItem> items;

  const ShopCategory({
    required this.label,
    required this.icon,
    required this.items,
  });
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int userCoins = 12500;
  int selectedClothesCategory = 0;
  int selectedFurnitureCategory = 0;

  final List<ShopCategory> clothesCategories = const [
    ShopCategory(
      label: 'Chaussures',
      icon: Icons.ice_skating,
      items: [
        ShopItem(
          name: 'Baskets Coeur',
          price: 180,
          imagePath: 'assets/clothes/chaussures/sh1.jpeg',
        ),
        ShopItem(
          name: 'Bottes Roses',
          price: 260,
          imagePath: 'assets/clothes/chaussures/sh2.jpeg',
        ),
        ShopItem(
          name: 'Sandales Ruban',
          price: 140,
          imagePath: 'assets/clothes/chaussures/sh3.jpeg',
        ),
      ],
    ),
    ShopCategory(
      label: 'Accessoires',
      icon: Icons.diamond,
      items: [
        ShopItem(
          name: 'Collier Perle',
          price: 90,
          imagePath: 'assets/clothes/accessoires/a1.jpeg',
        ),
        ShopItem(
          name: 'Bracelet Etoile',
          price: 110,
          imagePath: 'assets/clothes/accessoires/a2.jpeg',
        ),
        ShopItem(
          name: 'Sac Nuage',
          price: 200,
          imagePath: 'assets/clothes/accessoires/a3.jpeg',
        ),
      ],
    ),
    ShopCategory(
      label: 'Robes',
      icon: Icons.checkroom,
      items: [
        ShopItem(
          name: 'Robe Princesse',
          price: 250,
          imagePath: 'assets/clothes/robes/d1.jpeg',
        ),
        ShopItem(
          name: 'Robe Bonbon',
          price: 320,
          imagePath: 'assets/clothes/robes/d2.jpeg',
        ),
        ShopItem(
          name: 'Robe Etoile',
          price: 380,
          imagePath: 'assets/clothes/robes/d3.jpeg',
        ),
      ],
    ),
    ShopCategory(
      label: 'Pantalons',
      icon: Icons.accessibility_new,
      items: [
        ShopItem(
          name: 'Jean Pastel',
          price: 220,
          imagePath: 'assets/clothes/pantalons/p1.jpeg',
        ),
        ShopItem(
          name: 'Pantalon Rose',
          price: 240,
          imagePath: 'assets/clothes/pantalons/p2.jpeg',
        ),
        ShopItem(
          name: 'Short Kawaii',
          price: 160,
          imagePath: 'assets/clothes/pantalons/p3.jpeg',
        ),
      ],
    ),
    ShopCategory(
      label: 'T-shirts',
      icon: Icons.dry_cleaning,
      items: [
        ShopItem(
          name: 'T-shirt Chat',
          price: 130,
          imagePath: 'assets/clothes/tshirts/t1.jpeg',
        ),
        ShopItem(
          name: 'Sweat Ours',
          price: 100,
          imagePath: 'assets/clothes/tshirts/t2.jpeg',
        ),
        ShopItem(
          name: 'Blouson Cuir Rose',
          price: 300,
          imagePath: 'assets/clothes/tshirts/t3.jpeg',
        ),
      ],
    ),
  ];

  final List<ShopCategory> furnitureCategories = const [
    ShopCategory(
      label: 'Lits',
      icon: Icons.bed,
      items: [
        ShopItem(
          name: 'Lit Coeur',
          price: 800,
          imagePath: 'assets/furniture/lits/l1.jpeg',
        ),
        ShopItem(
          name: 'Lit Nuage',
          price: 950,
          imagePath: 'assets/furniture/lits/l2.jpeg',
        ),
        ShopItem(
          name: 'Lit Princesse',
          price: 1200,
          imagePath: 'assets/furniture/lits/l3.jpeg',
        ),
      ],
    ),
    ShopCategory(
      label: 'Lampes',
      icon: Icons.light,
      items: [
        ShopItem(
          name: 'Lampe Lune',
          price: 350,
          imagePath: 'assets/furniture/lampes/o1.jpeg',
        ),
        ShopItem(
          name: 'Lampe Coeur',
          price: 400,
          imagePath: 'assets/furniture/lampes/o2.jpeg',
        ),
        ShopItem(
          name: 'Lampe Etoile',
          price: 450,
          imagePath: 'assets/furniture/lampes/o3.jpeg',
        ),
      ],
    ),
    ShopCategory(
      label: 'Bureaux',
      icon: Icons.desk,
      items: [
        ShopItem(
          name: 'Bureau Rose',
          price: 900,
          imagePath: 'assets/furniture/bureaux/b1.jpeg',
        ),
        ShopItem(
          name: 'Coiffeuse Princesse',
          price: 1500,
          imagePath: 'assets/furniture/bureaux/b2.jpeg',
        ),
        ShopItem(
          name: 'Chaise Bow-tique',
          price: 400,
          imagePath: 'assets/furniture/bureaux/b3.jpeg',
        ),
      ],
    ),
    ShopCategory(
      label: 'Tapis',
      icon: Icons.layers,
      items: [
        ShopItem(
          name: 'Tapis Nuage',
          price: 300,
          imagePath: 'assets/furniture/tapis/t1.jpeg',
        ),
        ShopItem(
          name: 'Tapis Coeur',
          price: 350,
          imagePath: 'assets/furniture/tapis/t2.jpeg',
        ),
        ShopItem(
          name: 'Tapis Etoile',
          price: 420,
          imagePath: 'assets/furniture/tapis/t3.jpeg',
        ),
      ],
    ),
  ];

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

  String _formatCoins(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
  }

  void _showPurchaseConfirmation(ShopItem item) {
    final remainingCoins = userCoins - item.price;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: 310,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF8).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEBC1B3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A4C93).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "CONFIRMER L'ACHAT",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF725062),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                // À la place de : Icon(item.icon, size: 54, color: const Color(0xFFE88FA0)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    item.imagePath,
                    height: 70, // Ajuste la taille selon tes images
                    width: 70,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4F3542),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${item.price} TC',
                  style: const TextStyle(
                    color: Color(0xFF8C7783),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Voulez-vous vraiment acheter cette\n${item.name} ?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5A4852),
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cout : ${item.price} TC\nVotre solde apres achat : ${_formatCoins(remainingCoins)} TC',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5B4650),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PillButton(
                        label: 'CONFIRMER',
                        color: const Color(0xFFB59ADF),
                        textColor: Colors.white,
                        onPressed: userCoins >= item.price
                            ? () {
                                setState(() => userCoins -= item.price);
                                Navigator.of(context).pop();
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PillButton(
                        label: 'ANNULER',
                        color: const Color(0xFFF4CAD2),
                        textColor: const Color(0xFF7E4353),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              const _PastelBedroomBackground(),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: isWide ? 44 : 58,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8BCFF0), Color(0xFFFFC1D1)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Store',
                    style: TextStyle(
                      color: Color(0xFF604052),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 430 : 520,
                      maxHeight: isWide ? constraints.maxHeight - 62 : 660,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: isWide ? 42 : 56,
                        bottom: 10,
                        left: 12,
                        right: 12,
                      ),
                      child: Column(
                        children: [
                          _CoinsBar(coins: _formatCoins(userCoins)),
                          const SizedBox(height: 8),
                          _CategoryTabs(controller: _tabController),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.42),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.64),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6C4D73,
                                    ).withValues(alpha: 0.18),
                                    blurRadius: 14,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _CategorizedShop(
                                    categories: clothesCategories,
                                    selectedIndex: selectedClothesCategory,
                                    onCategorySelected: (index) {
                                      setState(
                                        () => selectedClothesCategory = index,
                                      );
                                    },
                                    onBuy: _showPurchaseConfirmation,
                                  ),
                                  _CategorizedShop(
                                    categories: furnitureCategories,
                                    selectedIndex: selectedFurnitureCategory,
                                    onCategorySelected: (index) {
                                      setState(
                                        () => selectedFurnitureCategory = index,
                                      );
                                    },
                                    onBuy: _showPurchaseConfirmation,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _ReturnButton(
                            onPressed: () => Navigator.maybePop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const _Mascot(alignment: Alignment.bottomLeft, mirror: false),
              const _Mascot(alignment: Alignment.bottomRight, mirror: true),
            ],
          );
        },
      ),
    );
  }
}

class _CoinsBar extends StatelessWidget {
  final String coins;

  const _CoinsBar({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.monetization_on, color: Color(0xFF86A58D), size: 18),
        const SizedBox(width: 5),
        Text(
          'Vos Coins : ',
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.68),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '$coins TC',
          style: const TextStyle(
            color: Color(0xFF3D3438),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final TabController controller;

  const _CategoryTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF6B4051),
        unselectedLabelColor: const Color(0xFF5F6968),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: const Color(0xFFFFCBD9).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checkroom, size: 17),
                SizedBox(width: 6),
                Text('VETEMENTS'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.weekend, size: 17),
                SizedBox(width: 6),
                Text('MEUBLES'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorizedShop extends StatelessWidget {
  final List<ShopCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<ShopItem> onBuy;

  const _CategorizedShop({
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCategory = categories[selectedIndex];

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _SubCategoryButton(
                label: category.label,
                icon: category.icon,
                selected: index == selectedIndex,
                onPressed: () => onCategorySelected(index),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _ShopGrid(items: selectedCategory.items, onBuy: onBuy),
        ),
      ],
    );
  }
}

class _SubCategoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  const _SubCategoryButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: selected ? 2 : 0,
          backgroundColor: selected
              ? const Color(0xFFA891DE)
              : Colors.white.withValues(alpha: 0.78),
          foregroundColor: selected ? Colors.white : const Color(0xFF6B4051),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected
                  ? const Color(0xFFA891DE)
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopGrid extends StatelessWidget {
  final List<ShopItem> items;
  final ValueChanged<ShopItem> onBuy;

  const _ShopGrid({required this.items, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 0.86,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ShopCard(item: item, onBuy: () => onBuy(item));
      },
    );
  }
}

class _ShopCard extends StatelessWidget {
  final ShopItem item;
  final VoidCallback onBuy;

  const _ShopCard({required this.item, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: // À la place de : Icon(item.icon, size: 54, color: const Color(0xFFE88FA0)),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item.imagePath,
                  height: 70, // Ajuste la taille selon tes images
                  width: 70,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF4B3C43),
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.price} TC',
            style: const TextStyle(
              color: Color(0xFF82737B),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 24,
            width: 82,
            child: _PillButton(
              label: 'ACHETER >',
              color: const Color(0xFFA891DE),
              textColor: Colors.white,
              onPressed: onBuy,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;
  final double fontSize;

  const _PillButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shadowColor: color.withValues(alpha: 0.35),
        backgroundColor: color,
        disabledBackgroundColor: const Color(0xFFD4CED7),
        foregroundColor: textColor,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ReturnButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ReturnButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 34,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: const Color(0xFF75CFC5).withValues(alpha: 0.36),
          backgroundColor: const Color(0xFFBDECE4),
          foregroundColor: const Color(0xFF55706B),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.white, width: 1.4),
          ),
        ),
        child: const Text(
          'Retour',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _PastelBedroomBackground extends StatelessWidget {
  const _PastelBedroomBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/background/store.jpeg', // ✅ ton fichier
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class _Mascot extends StatelessWidget {
  final Alignment alignment;
  final bool mirror;

  const _Mascot({required this.alignment, required this.mirror});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 18),
        child: Transform.scale(
          scaleX: mirror ? -1 : 1,
          child: Icon(
            Icons.face_3,
            size: 72,
            color: const Color(0xFFF6A5B6).withValues(alpha: 0.86),
          ),
        ),
      ),
    );
  }
}
