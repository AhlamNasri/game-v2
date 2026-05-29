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

class _InventoryPanel extends StatefulWidget {
  final List<InventoryItem> inventory;
  final VoidCallback onShopPressed;
  final VoidCallback onClose;

  const _InventoryPanel({
    required this.inventory,
    required this.onShopPressed,
    required this.onClose,
  });

  @override
  State<_InventoryPanel> createState() => _InventoryPanelState();
}

class _InventoryPanelState extends State<_InventoryPanel> {
  final _scrollController = ScrollController();
  bool _canScrollUp = false;
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
  }

  @override
  void didUpdateWidget(covariant _InventoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inventory.length != widget.inventory.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients || !mounted) return;
    final position = _scrollController.position;
    final nextCanScrollUp = position.pixels > position.minScrollExtent + 2;
    final nextCanScrollDown = position.pixels < position.maxScrollExtent - 2;
    if (_canScrollUp == nextCanScrollUp &&
        _canScrollDown == nextCanScrollDown) {
      return;
    }
    setState(() {
      _canScrollUp = nextCanScrollUp;
      _canScrollDown = nextCanScrollDown;
    });
  }

  Future<void> _scrollInventory(double direction) async {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final viewport = position.viewportDimension;
    final target = (position.pixels + viewport * 0.72 * direction)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();

    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    _updateScrollButtons();
  }

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
                      child: _SidebarShopButton(
                        onPressed: widget.onShopPressed,
                      ),
                    ),
                    const SizedBox(width: 6),
                    RoomRoundIconButton(
                      icon: Icons.keyboard_double_arrow_left,
                      tooltip: 'Hide inventory',
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),
              _InventoryScrollButton(
                icon: Icons.keyboard_arrow_up,
                tooltip: 'Scroll inventory up',
                enabled: _canScrollUp,
                onPressed: () => _scrollInventory(-1),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(scrollbars: false),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    thickness: 5,
                    radius: const Radius.circular(999),
                    child: GridView.builder(
                      controller: _scrollController,
                      primary: false,
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
                      itemCount: widget.inventory.length,
                      itemBuilder: (context, index) {
                        final item = widget.inventory[index];
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
              _InventoryScrollButton(
                icon: Icons.keyboard_arrow_down,
                tooltip: 'Scroll inventory down',
                enabled: _canScrollDown,
                onPressed: () => _scrollInventory(1),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryScrollButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _InventoryScrollButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Material(
          color: enabled
              ? RoomUi.accent
              : RoomUi.accent.withValues(alpha: 0.28),
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 30,
              width: double.infinity,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
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
                const Icon(Icons.chair_alt, color: Color(0xFFB43779)),
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
