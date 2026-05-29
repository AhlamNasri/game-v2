import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../theme/room_ui.dart';
import 'room_buttons.dart';

class InventoryDrawer extends StatelessWidget {
  final bool visible;
  final List<InventoryItem> inventory;
  final VoidCallback onShopPressed;
  final VoidCallback onClose;

  const InventoryDrawer({
    super.key,
    required this.visible,
    required this.inventory,
    required this.onShopPressed,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = math.min(230.0, math.max(170.0, screenWidth * 0.28));

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(-1.08, 0),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: drawerWidth,
              height: double.infinity,
              child: _InventoryPanel(
                inventory: inventory,
                onShopPressed: onShopPressed,
                onClose: onClose,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryPanel extends StatelessWidget {
  final List<InventoryItem> inventory;
  final VoidCallback onShopPressed;
  final VoidCallback onClose;

  const _InventoryPanel({
    required this.inventory,
    required this.onShopPressed,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [RoomUi.softPanel, Color(0xFFFFD7EA)],
            ),
            border: Border(
              right: BorderSide(color: Color(0xFFF2A6CA), width: 2),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _SidebarShopButton(onPressed: onShopPressed),
                    ),
                    const SizedBox(width: 6),
                    RoomRoundIconButton(
                      icon: Icons.keyboard_double_arrow_left,
                      tooltip: 'Hide inventory',
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(scrollbars: false),
                  child: Scrollbar(
                    thumbVisibility: true,
                    thickness: 5,
                    radius: const Radius.circular(999),
                    child: GridView.builder(
                      primary: true,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 4, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                      itemCount: inventory.length,
                      itemBuilder: (context, index) {
                        final item = inventory[index];
                        return Draggable<InventoryItem>(
                          data: item,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Image.asset(
                              item.asset,
                              width: 86,
                              errorBuilder: (_, _, _) => const SizedBox(
                                width: 86,
                                height: 86,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFECF6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chair,
                                    color: Color(0xFFB43779),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.35,
                            child: _InventoryTile(item: item),
                          ),
                          child: _InventoryTile(item: item),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final InventoryItem item;

  const _InventoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.name,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF3B7D3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFAE5D8C).withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            item.asset,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.lock_open, color: Color(0xFFB43779)),
          ),
        ),
      ),
    );
  }
}

class _SidebarShopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SidebarShopButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Go Shop',
      child: Material(
        color: RoomUi.accent,
        shape: const StadiumBorder(),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: const SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront, color: Colors.white, size: 19),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Go Shop',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
