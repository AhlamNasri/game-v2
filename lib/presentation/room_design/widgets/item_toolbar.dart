import 'package:flutter/material.dart';

import '../theme/room_ui.dart';
import 'room_buttons.dart';

class ItemToolbar extends StatelessWidget {
  final VoidCallback onLayerDown;
  final VoidCallback onLayerUp;
  final VoidCallback onRotate;
  final VoidCallback onDelete;

  const ItemToolbar({
    super.key,
    required this.onLayerDown,
    required this.onLayerUp,
    required this.onRotate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      shape: const StadiumBorder(),
      elevation: 5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: RoomUi.accent.withValues(alpha: 0.42)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoomMiniIconButton(
              icon: Icons.flip_to_back,
              tooltip: 'Send backward',
              onPressed: onLayerDown,
            ),
            const SizedBox(width: 6),
            RoomMiniIconButton(
              icon: Icons.rotate_right,
              tooltip: 'Rotate',
              onPressed: onRotate,
            ),
            const SizedBox(width: 6),
            RoomMiniIconButton(
              icon: Icons.flip_to_front,
              tooltip: 'Bring forward',
              onPressed: onLayerUp,
            ),
            const SizedBox(width: 6),
            RoomMiniIconButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
