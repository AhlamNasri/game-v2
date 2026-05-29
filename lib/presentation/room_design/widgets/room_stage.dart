import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/room_definition.dart';
import '../models/room_item.dart';
import 'placed_room_item.dart';

class RoomStage extends StatelessWidget {
  final RoomDefinition room;
  final RoomItem? selectedItem;
  final GlobalKey viewportKey;
  final ValueChanged<Size> onStageSizeChanged;
  final void Function(InventoryItem item, Offset globalOffset) onAcceptItem;
  final VoidCallback onClearSelection;
  final ValueChanged<RoomItem> onItemSelected;
  final ValueChanged<RoomItem> onItemRotated;
  final void Function(RoomItem item, int direction) onItemLayerChanged;
  final ValueChanged<RoomItem> onItemRemoved;
  final ValueChanged<RoomItem> onItemChanged;     // was VoidCallback
  final ValueChanged<RoomItem> onItemChangeEnd;   // was VoidCallback
  final double Function() currentCanvasScale;

  const RoomStage({
    super.key,
    required this.room,
    required this.selectedItem,
    required this.viewportKey,
    required this.onStageSizeChanged,
    required this.onAcceptItem,
    required this.onClearSelection,
    required this.onItemSelected,
    required this.onItemRotated,
    required this.onItemLayerChanged,
    required this.onItemRemoved,
    required this.onItemChanged,
    required this.onItemChangeEnd,
    required this.currentCanvasScale,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<InventoryItem>(
      hitTestBehavior: HitTestBehavior.translucent,
      onAcceptWithDetails: (details) =>
          onAcceptItem(details.data, details.offset),
      builder: (context, candidate, rejected) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final stageSize = Size(constraints.maxWidth, constraints.maxHeight);
            onStageSizeChanged(stageSize);

            return SizedBox.expand(
              key: viewportKey,
              child: Stack(
                children: [
                  // ── Background: single image, fills 100% of screen ──
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onClearSelection,
                      child: Image.asset(
                        room.background,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),

                  // ── Subtle ambient overlay ──
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.18),
                              Colors.transparent,
                              const Color(0xFF5C2D53).withValues(alpha: 0.12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Ceiling trim ──
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(child: _CeilingTrim()),
                  ),

                  // ── Placed items ──
                  Positioned.fill(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ..._paintOrderedItems(room.placedItems).map(
                          (item) => PlacedRoomItem(
                            item: item,
                            selected: selectedItem == item,
                            stageSize: stageSize,
                            onSelect: () => onItemSelected(item),
                            onToggleSelection: () {
                              if (selectedItem == item) {
                                onClearSelection();
                              } else {
                                onItemSelected(item);
                              }
                            },
                            onChanged: onItemChanged,    // passes updated draft up
                            onChangeEnd: onItemChangeEnd, // passes final draft up
                            onRotate: () => onItemRotated(item),
                            onLayerDown: () => onItemLayerChanged(item, -1),
                            onLayerUp: () => onItemLayerChanged(item, 1),
                            onDelete: () => onItemRemoved(item),
                            currentCanvasScale: currentCanvasScale,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Drag-over highlight ──
                  if (candidate.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE0549D),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<RoomItem> _paintOrderedItems(List<RoomItem> items) {
    return List<RoomItem>.of(items)..sort((a, b) {
      final layerCompare = a.layer.compareTo(b.layer);
      if (layerCompare != 0) return layerCompare;
      return (a.y + a.width).compareTo(b.y + b.width);
    });
  }
}

class _CeilingTrim extends StatelessWidget {
  const _CeilingTrim();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFFE8D9DD).withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFBFA7AE), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}