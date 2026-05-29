import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/room_item.dart';
import 'item_toolbar.dart';

class PlacedRoomItem extends StatefulWidget {
  final RoomItem item;
  final bool selected;
  final Size stageSize;
  final VoidCallback onSelect;
  final VoidCallback onToggleSelection;
  final ValueChanged<RoomItem> onChanged;
  final ValueChanged<RoomItem> onChangeEnd;
  final VoidCallback onRotate;
  final VoidCallback onLayerDown;
  final VoidCallback onLayerUp;
  final VoidCallback onDelete;
  final double Function() currentCanvasScale;

  const PlacedRoomItem({
    super.key,
    required this.item,
    required this.selected,
    required this.stageSize,
    required this.onSelect,
    required this.onToggleSelection,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onRotate,
    required this.onLayerDown,
    required this.onLayerUp,
    required this.onDelete,
    required this.currentCanvasScale,
  });

  @override
  State<PlacedRoomItem> createState() => _PlacedRoomItemState();
}

class _PlacedRoomItemState extends State<PlacedRoomItem> {
  // Local draft used only during an active gesture.
  // Committed to the parent via onChanged / onChangeEnd.
  late RoomItem _draft;
  double? _gestureStartWidth;
  double? _gestureStartRotation;

  @override
  void initState() {
    super.initState();
    _draft = widget.item;
  }

  @override
  void didUpdateWidget(covariant PlacedRoomItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync from parent when no gesture is in progress,
    // so mid-gesture frames aren't overwritten.
    if (_gestureStartWidth == null && _gestureStartRotation == null) {
      _draft = widget.item;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _draft;
    const toolbarWidth = 156.0;
    const toolbarHeight = 40.0;
    const toolbarGap = 8.0;
    final toolbarExtra = widget.selected
        ? math.max(0.0, (toolbarWidth - item.width) / 2)
        : 0.0;
    final left = math.max(0.0, item.x - toolbarExtra);
    final top = widget.selected
        ? math.max(0.0, item.y - toolbarHeight - toolbarGap)
        : item.y;
    final itemLeft = item.x - left;
    final itemTop = item.y - top;
    final touchWidth = widget.selected
        ? math.max(item.width + toolbarExtra * 2, toolbarWidth)
        : item.width;
    final touchHeight = widget.selected ? itemTop + item.width + 8 : item.width;

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: touchWidth,
        height: touchHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (widget.selected)
              Positioned(
                left: (touchWidth - toolbarWidth) / 2,
                top: 0,
                child: ItemToolbar(
                  onLayerDown: widget.onLayerDown,
                  onLayerUp: widget.onLayerUp,
                  onRotate: widget.onRotate,
                  onDelete: widget.onDelete,
                ),
              ),
            Positioned(
              left: itemLeft,
              top: itemTop,
              width: item.width,
              height: item.width,
              child: Transform.rotate(
                angle: item.rotation,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onToggleSelection,
                  onScaleStart: (_) {
                    _gestureStartWidth = item.width;
                    _gestureStartRotation = item.rotation;
                    widget.onSelect();
                  },
                  onScaleUpdate: _handleScaleUpdate,
                  onScaleEnd: (_) {
                    _gestureStartWidth = null;
                    _gestureStartRotation = null;
                    widget.onChangeEnd(_draft);
                  },
                  child: Image.asset(
                    item.asset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount >= 2) {
        final startWidth = _gestureStartWidth ?? _draft.width;
        final startRotation = _gestureStartRotation ?? _draft.rotation;
        final newWidth =
            (startWidth * details.scale).clamp(42, 420).toDouble();
        final newRotation =
            _normalizeRotation(startRotation + details.rotation);
        _draft = _draft.copyWith(width: newWidth, rotation: newRotation);
        _draft = _clampToStage(_draft);
      } else {
        final scale = widget.currentCanvasScale().clamp(0.25, 4).toDouble();
        final maxX = _maxCoordinate(widget.stageSize.width, _draft.width);
        final maxY = _maxCoordinate(widget.stageSize.height, _draft.width);
        _draft = _draft.copyWith(
          x: (_draft.x + details.focalPointDelta.dx / scale)
              .clamp(0, maxX)
              .toDouble(),
          y: (_draft.y + details.focalPointDelta.dy / scale)
              .clamp(0, maxY)
              .toDouble(),
        );
      }
    });
    widget.onChanged(_draft);
  }

  RoomItem _clampToStage(RoomItem item) {
    return item.copyWith(
      x: item.x.clamp(0, _maxCoordinate(widget.stageSize.width, item.width)),
      y: item.y.clamp(0, _maxCoordinate(widget.stageSize.height, item.width)),
    );
  }

  double _maxCoordinate(double extent, double itemWidth) {
    if (extent <= 0) return double.infinity;
    return (extent - itemWidth).clamp(0, double.infinity).toDouble();
  }

  double _normalizeRotation(double angle) {
    final fullTurn = math.pi * 2;
    final normalized = angle % fullTurn;
    return normalized < 0 ? normalized + fullTurn : normalized;
  }
}