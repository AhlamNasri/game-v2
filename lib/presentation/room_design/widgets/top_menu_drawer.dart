import 'package:flutter/material.dart';

import '../models/room_definition.dart';
import '../theme/room_ui.dart';
import 'room_buttons.dart';

class TopMenuDrawer extends StatelessWidget {
  final bool visible;
  final int coins;
  final List<RoomDefinition> rooms;
  final int activeRoomIndex;
  final String playerName;
  final int playerLevel;
  final bool saving;
  final bool inventoryVisible;
  final VoidCallback onToggleMenu;
  final VoidCallback onBack;
  final VoidCallback onGoToCloset;
  final VoidCallback onCompetitionMode;
  final VoidCallback onSettings;
  final ValueChanged<int> onRoomSelected;
  final VoidCallback onUnlockSecondRoom;
  final VoidCallback onToggleInventory;

  const TopMenuDrawer({
    super.key,
    required this.visible,
    required this.coins,
    required this.rooms,
    required this.activeRoomIndex,
    required this.playerName,
    required this.playerLevel,
    required this.saving,
    required this.inventoryVisible,
    required this.onToggleMenu,
    required this.onBack,
    required this.onGoToCloset,
    required this.onCompetitionMode,
    required this.onSettings,
    required this.onRoomSelected,
    required this.onUnlockSecondRoom,
    required this.onToggleInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!inventoryVisible)
          Positioned(
            top: 12,
            left: 12,
            child: IgnorePointer(
              ignoring: visible,
              child: AnimatedOpacity(
                opacity: visible ? 0 : 1,
                duration: const Duration(milliseconds: 140),
                child: ProfileBadge(
                  key: const ValueKey('collapsed-profile-badge'),
                  name: playerName,
                  level: playerLevel,
                ),
              ),
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: IgnorePointer(
            ignoring: visible,
            child: AnimatedOpacity(
              opacity: visible ? 0 : 1,
              duration: const Duration(milliseconds: 140),
              child: RoomRoundIconButton(
                icon: Icons.menu,
                tooltip: 'Open menu',
                onPressed: onToggleMenu,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, -1.15),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: Align(
                  alignment: Alignment.topRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: _MenuBar(
                      coins: coins,
                      rooms: rooms,
                      activeRoomIndex: activeRoomIndex,
                      playerName: playerName,
                      playerLevel: playerLevel,
                      saving: saving,
                      inventoryVisible: inventoryVisible,
                      onClose: onToggleMenu,
                      onBack: onBack,
                      onGoToCloset: onGoToCloset,
                      onCompetitionMode: onCompetitionMode,
                      onSettings: onSettings,
                      onRoomSelected: onRoomSelected,
                      onUnlockSecondRoom: onUnlockSecondRoom,
                      onToggleInventory: onToggleInventory,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuBar extends StatelessWidget {
  final int coins;
  final List<RoomDefinition> rooms;
  final int activeRoomIndex;
  final String playerName;
  final int playerLevel;
  final bool saving;
  final bool inventoryVisible;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onGoToCloset;
  final VoidCallback onCompetitionMode;
  final VoidCallback onSettings;
  final ValueChanged<int> onRoomSelected;
  final VoidCallback onUnlockSecondRoom;
  final VoidCallback onToggleInventory;

  const _MenuBar({
    required this.coins,
    required this.rooms,
    required this.activeRoomIndex,
    required this.playerName,
    required this.playerLevel,
    required this.saving,
    required this.inventoryVisible,
    required this.onClose,
    required this.onBack,
    required this.onGoToCloset,
    required this.onCompetitionMode,
    required this.onSettings,
    required this.onRoomSelected,
    required this.onUnlockSecondRoom,
    required this.onToggleInventory,
  });

  @override
  Widget build(BuildContext context) {
    final controls = <Widget>[
      RoomRoundIconButton(
        icon: Icons.keyboard_double_arrow_up,
        tooltip: 'Hide menu',
        onPressed: onClose,
      ),
      RoomRoundIconButton(
        icon: Icons.arrow_back,
        tooltip: 'Back',
        onPressed: onBack,
      ),
      if (!inventoryVisible) ProfileBadge(name: playerName, level: playerLevel),
      _AutosaveStatus(saving: saving),
      _StatusPill(
        icon: Icons.monetization_on,
        label: '$coins',
        color: RoomUi.accent,
      ),
      for (var index = 0; index < rooms.length; index++)
        _RoomChip(
          label: rooms[index].name,
          selected: index == activeRoomIndex,
          onSelected: () => onRoomSelected(index),
        ),
      if (rooms.length < 2) _UnlockRoomButton(onPressed: onUnlockSecondRoom),
      _MenuActionChip(
        icon: Icons.checkroom,
        label: 'Go to Closet',
        tooltip: 'Go to Closet',
        onPressed: onGoToCloset,
      ),
      _MenuActionChip(
        icon: Icons.emoji_events,
        label: 'Competition',
        tooltip: 'Competition Mode',
        onPressed: onCompetitionMode,
      ),
      RoomRoundIconButton(
        icon: inventoryVisible ? Icons.chair : Icons.chair_alt_outlined,
        tooltip: inventoryVisible ? 'Hide inventory' : 'Show inventory',
        onPressed: onToggleInventory,
      ),
      RoomRoundIconButton(
        icon: Icons.settings,
        tooltip: 'Settings',
        onPressed: onSettings,
      ),
    ];

    return Material(
      color: RoomUi.softPanel.withValues(alpha: 0.96),
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF2A6CA), width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 980) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: controls,
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < controls.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    controls[index],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProfileBadge extends StatelessWidget {
  final String name;
  final int level;

  const ProfileBadge({super.key, required this.name, required this.level});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$name - Lvl $level',
      child: Container(
        height: 40,
        constraints: const BoxConstraints(maxWidth: 190),
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: RoomUi.accent.withValues(alpha: 0.45),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFAE5D8C).withValues(alpha: 0.14),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle, color: RoomUi.accent, size: 24),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RoomUi.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Lvl $level',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RoomUi.pillText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutosaveStatus extends StatelessWidget {
  final bool saving;

  const _AutosaveStatus({required this.saving});

  @override
  Widget build(BuildContext context) {
    return _StatusPill(
      icon: saving ? Icons.cloud_sync : Icons.cloud_done,
      label: saving ? 'Saving' : 'Auto',
      color: saving ? const Color(0xFF8A5BE8) : const Color(0xFF4B9E67),
    );
  }
}

class _MenuActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  const _MenuActionChip({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: Colors.white),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        onPressed: onPressed,
        backgroundColor: RoomUi.accent,
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: RoomUi.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _RoomChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      avatar: Icon(
        Icons.meeting_room,
        size: 16,
        color: selected ? Colors.white : RoomUi.pillText,
      ),
      onSelected: (_) => onSelected(),
      selectedColor: RoomUi.accent,
      backgroundColor: Colors.white.withValues(alpha: 0.94),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : RoomUi.pillText,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _UnlockRoomButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _UnlockRoomButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.add_home, size: 18, color: Colors.white),
      label: const Text('Unlock Room 2'),
      onPressed: onPressed,
      backgroundColor: RoomUi.accent,
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
