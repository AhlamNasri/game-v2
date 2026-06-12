import 'dart:async';
import 'dart:math' as math;

import 'package:fashion_room_girls/data/services/lobby_service.dart';
import 'package:fashion_room_girls/data/services/user_service.dart';
import 'package:fashion_room_girls/presentation/room_design/data/room_assets.dart';
import 'package:fashion_room_girls/presentation/room_design/data/room_repository.dart';
import 'package:fashion_room_girls/presentation/room_design/data/room_save_state.dart';
import 'package:fashion_room_girls/presentation/room_design/models/inventory_item.dart';
import 'package:fashion_room_girls/presentation/room_design/models/room_definition.dart';
import 'package:fashion_room_girls/presentation/room_design/models/room_item.dart';
import 'package:fashion_room_girls/presentation/room_design/theme/room_ui.dart';
import 'package:fashion_room_girls/presentation/room_design/utils/room_item_sizing.dart';
import 'package:fashion_room_girls/presentation/room_design/widgets/inventory_drawer.dart';
import 'package:fashion_room_girls/presentation/room_design/widgets/room_stage.dart';
import 'package:fashion_room_girls/presentation/room_design/widgets/top_menu_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with WidgetsBindingObserver {
  static const _autosaveDelay = Duration(milliseconds: 450);

  final _repository = RoomRepository();
  final _viewportKey = GlobalKey();

  List<InventoryItem> _inventory = [];
  RoomSaveState? _saveState;
  RoomItem? _selectedItem;
  StreamSubscription<User?>? _authSubscription;
  bool _loading = true;
  bool _saving = false;
  bool _inventoryVisible = false;
  bool _menuVisible = false;
  bool _saveInFlight = false;
  bool _saveAgainAfterCurrent = false;
  bool _isDisposing = false;
  Timer? _autosaveTimer;
  Size _stageSize = Size.zero;

  RoomDefinition get _activeRoom =>
      _saveState!.rooms[_saveState!.activeRoomIndex];

  String get _playerName {
    final user = _repository.currentUser;
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;

    return user == null ? 'Guest' : 'Player';
  }

  int get _playerLevel => _saveState?.playerLevel ?? 1;

  Future<void> _lockLandscapeOrientation() {
    return SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restorePreferredOrientations() {
    return _lockLandscapeOrientation();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_lockLandscapeOrientation());
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      if (user == null && _saveState?.userId != 'guest') {
        await _saveRoom(silent: true);
      }
      await _loadData();
    });
    unawaited(_loadData());
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    _autosaveTimer?.cancel();
    unawaited(_saveRoom(silent: true));
    unawaited(_restorePreferredOrientations());
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      unawaited(_saveRoom(silent: true));
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final saveState = await _repository.load();
      final inventory = await RoomAssets.loadAvailableItems(
        saveState.inventory,
      );
      if (!mounted) return;
      setState(() {
        _saveState = saveState;
        _inventory = inventory;
        _selectedItem = null;
        _loading = false;
      });
    } on RoomLoadException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(error.message);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Firebase room error: ${error.message ?? error.code}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Could not load room data: $error');
    }
  }

  Future<void> _saveRoom({bool silent = false}) async {
    final state = _saveState;
    if (state == null) return;

    _autosaveTimer?.cancel();
    if (_saveInFlight) {
      _saveAgainAfterCurrent = true;
      if (mounted && !_isDisposing && !_saving) {
        setState(() => _saving = true);
      }
      return;
    }

    _saveInFlight = true;
    if (mounted && !_isDisposing && !_saving) {
      setState(() => _saving = true);
    }
    try {
      await _repository.save(state);
      if (!silent && mounted) _showMessage('Room saved');
    } finally {
      _saveInFlight = false;
      final saveAgain = _saveAgainAfterCurrent;
      _saveAgainAfterCurrent = false;

      if (saveAgain) {
        await _saveRoom(silent: true);
      } else if (mounted && !_isDisposing) {
        setState(() => _saving = false);
      } else {
        _saving = false;
      }
    }
  }

  void _queueAutoSave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(
      _autosaveDelay,
      () => unawaited(_saveRoom(silent: true)),
    );
    if (mounted && !_isDisposing && !_saving) setState(() => _saving = true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF7E3565),
      ),
    );
  }

  RoomSaveState _withUpdatedActiveRoom(
    RoomSaveState state,
    RoomDefinition updatedRoom,
  ) {
    final updatedRooms = List<RoomDefinition>.of(state.rooms);
    updatedRooms[state.activeRoomIndex] = updatedRoom;
    return state.copyWith(rooms: updatedRooms);
  }

  // Replaces the old item with the updated one by object identity,
  // then writes the result into _saveState cleanly.
  void _updateItem(RoomItem updated, {required RoomItem old}) {
    final state = _saveState;
    if (state == null) return;

    final updatedItems = _activeRoom.placedItems.map((i) {
      return identical(i, old) ? updated : i;
    }).toList();

    final updatedRoom = RoomDefinition(
      id: _activeRoom.id,
      name: _activeRoom.name,
      background: _activeRoom.background,
      unlockCost: _activeRoom.unlockCost,
      placedItems: updatedItems,
    );

    setState(() {
      _saveState = _withUpdatedActiveRoom(state, updatedRoom);
      // Keep _selectedItem in sync with the new object.
      if (_selectedItem != null && identical(_selectedItem, old)) {
        _selectedItem = updated;
      }
    });
  }

  Future<void> _unlockNextRoom() async {
    final state = _saveState;
    if (state == null) return;
    final nextRoom = state.nextLockedRoom;
    if (nextRoom == null) return;
    final cost = nextRoom.unlockCost;
    if (state.coins < cost) {
      _showMessage('Need $cost coins to unlock ${nextRoom.name}');
      return;
    }

    final confirmed = await _confirmRoomUnlock(nextRoom, state.coins);
    if (!confirmed) return;

    try {
      final updated = await _repository.unlockNextRoom(state);
      final inventory = await RoomAssets.loadAvailableItems(updated.inventory);
      if (!mounted) return;
      setState(() {
        _saveState = updated;
        _inventory = inventory;
        _selectedItem = null;
      });
      _showMessage('${nextRoom.name} unlocked!');
    } on RoomUnlockException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not unlock ${nextRoom.name}.');
    }
  }

  Future<bool> _confirmRoomUnlock(RoomDefinition room, int coins) async {
    final cost = room.unlockCost;
    final remaining = coins - cost;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RoomUi.softPanel,
        title: Text('Unlock ${room.name}?'),
        content: Text(
          'This will spend $cost coins. Your balance will be $remaining coins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.lock_open),
            label: const Text('Unlock'),
            style: FilledButton.styleFrom(
              backgroundColor: RoomUi.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _switchRoom(int index) {
    final state = _saveState;
    if (state == null ||
        index == state.activeRoomIndex ||
        index < 0 ||
        index >= state.rooms.length) {
      return;
    }
    setState(() {
      _saveState = state.copyWith(activeRoomIndex: index);
      _selectedItem = null;
    });
    unawaited(_saveRoom(silent: true));
  }

  double _currentCanvasScale() => 1;

  int _nextLayer() {
    if (_activeRoom.placedItems.isEmpty) return 0;
    return _activeRoom.placedItems.map((item) => item.layer).reduce(math.max) +
        1;
  }

  int _compareLayerOrder(RoomItem a, RoomItem b) {
    final layerCompare = a.layer.compareTo(b.layer);
    if (layerCompare != 0) return layerCompare;
    return (a.y + a.width).compareTo(b.y + b.width);
  }

  double _normalizeRotation(double angle) {
    final fullTurn = math.pi * 2;
    final normalized = angle % fullTurn;
    return normalized < 0 ? normalized + fullTurn : normalized;
  }

  void _addItem(InventoryItem inventoryItem, Offset globalOffset) {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final sceneOffset = box.globalToLocal(globalOffset);
    final state = _saveState;
    if (state == null) return;

    final itemWidth = defaultRoomItemWidth(inventoryItem.id);
    final stageWidth = _stageSize.width == 0
        ? box.size.width
        : _stageSize.width;
    final stageHeight = _stageSize.height == 0
        ? box.size.height
        : _stageSize.height;
    final maxX = (stageWidth - itemWidth).clamp(0, double.infinity).toDouble();
    final maxY = (stageHeight - itemWidth).clamp(0, double.infinity).toDouble();

    final newItem = RoomItem(
      name: inventoryItem.name,
      asset: inventoryItem.asset,
      x: (sceneOffset.dx - itemWidth / 2).clamp(0, maxX).toDouble(),
      y: (sceneOffset.dy - itemWidth / 2).clamp(0, maxY).toDouble(),
      width: itemWidth,
      layer: _nextLayer(),
    );

    final updatedRoom = RoomDefinition(
      id: _activeRoom.id,
      name: _activeRoom.name,
      background: _activeRoom.background,
      unlockCost: _activeRoom.unlockCost,
      placedItems: [..._activeRoom.placedItems, newItem],
    );

    setState(() {
      _saveState = _withUpdatedActiveRoom(state, updatedRoom);
      _selectedItem = null;
    });
    _queueAutoSave();
  }

  void _rotateItem(RoomItem item) {
    final state = _saveState;
    if (state == null) return;

    final rotated = item.copyWith(
      rotation: _normalizeRotation(item.rotation + math.pi / 12),
    );

    final updatedItems = _activeRoom.placedItems.map((i) {
      return identical(i, item) ? rotated : i;
    }).toList();

    final updatedRoom = RoomDefinition(
      id: _activeRoom.id,
      name: _activeRoom.name,
      background: _activeRoom.background,
      unlockCost: _activeRoom.unlockCost,
      placedItems: updatedItems,
    );

    setState(() {
      _saveState = _withUpdatedActiveRoom(state, updatedRoom);
      _selectedItem = rotated;
    });
    _queueAutoSave();
  }

  void _changeItemLayer(RoomItem item, int direction) {
    final state = _saveState;
    if (state == null || _activeRoom.placedItems.length < 2) return;

    // Build an ordered list using copyWith — no direct mutation.
    final ordered = List<RoomItem>.of(_activeRoom.placedItems)
      ..sort(_compareLayerOrder);

    // Assign normalised layer values immutably.
    final normalised = [
      for (var idx = 0; idx < ordered.length; idx++)
        ordered[idx].copyWith(layer: idx),
    ];

    final index = normalised.indexWhere(
      (i) => i.asset == item.asset && i.x == item.x && i.y == item.y,
    );
    if (index == -1) return;

    final targetIndex = (index + direction)
        .clamp(0, normalised.length - 1)
        .toInt();
    if (targetIndex == index) return;

    // Swap layers between the two items.
    final aLayer = normalised[index].layer;
    final bLayer = normalised[targetIndex].layer;
    final swapped = List<RoomItem>.of(normalised);
    swapped[index] = normalised[index].copyWith(layer: bLayer);
    swapped[targetIndex] = normalised[targetIndex].copyWith(layer: aLayer);

    final updatedRoom = RoomDefinition(
      id: _activeRoom.id,
      name: _activeRoom.name,
      background: _activeRoom.background,
      unlockCost: _activeRoom.unlockCost,
      placedItems: swapped,
    );

    setState(() {
      _saveState = _withUpdatedActiveRoom(state, updatedRoom);
      _selectedItem = swapped[index];
    });
    _queueAutoSave();
  }

  void _removeItem(RoomItem item) {
    final state = _saveState;
    if (state == null) return;

    final updatedRoom = RoomDefinition(
      id: _activeRoom.id,
      name: _activeRoom.name,
      background: _activeRoom.background,
      unlockCost: _activeRoom.unlockCost,
      placedItems: _activeRoom.placedItems.where((i) => i != item).toList(),
    );

    setState(() {
      _saveState = _withUpdatedActiveRoom(state, updatedRoom);
      _selectedItem = null;
    });
    _queueAutoSave();
  }

  void _toggleInventory() {
    setState(() {
      _inventoryVisible = !_inventoryVisible;
      if (_inventoryVisible) _menuVisible = false;
    });
  }

  void _navigateBack() {
    unawaited(_saveRoom(silent: true));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/menu');
    }
  }

  void _navigateToMenu() {
    unawaited(_saveRoom(silent: true));
    context.go('/menu');
  }

  void _navigateToCloset() {
    unawaited(_saveRoom(silent: true));
    context.go('/character');
  }

  void _openSettings() {
    unawaited(_saveRoom(silent: true));
    setState(() => _menuVisible = false);
    context.push('/settings');
  }

  Future<void> _openCompetitionMode() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!mounted) return;
        Navigator.pop(context);
        context.push('/login?roomId=none');
        return;
      }

      final Map<String, String?> localUser = await UserService().getLocalUser();

      final String myNickname = localUser['nickname']?.isNotEmpty == true
          ? localUser['nickname']!
          : _playerName;

      final String myAvatarId = localUser['avatarId']?.isNotEmpty == true
          ? localUser['avatarId']!
          : 'avatar1';

      final int myLevel = _saveState?.playerLevel ?? 1;

      final String roomId = await LobbyService().findOrCreateLobby(
        currentUserId: currentUser.uid,
        currentUserNickname: myNickname,
        currentUserAvatarId: myAvatarId,
        userLevel: myLevel,
      );

      if (!mounted) return;
      Navigator.pop(context);
      context.push('/lobby?roomId=$roomId');
    } catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not find a room: $error')),
      );
    }
  }

  Widget _buildRoomStage() {
    return RoomStage(
      room: _activeRoom,
      selectedItem: _selectedItem,
      viewportKey: _viewportKey,
      onStageSizeChanged: (size) => _stageSize = size,
      onAcceptItem: _addItem,
      onClearSelection: () => setState(() => _selectedItem = null),
      onItemSelected: (item) => setState(() => _selectedItem = item),
      onItemRotated: _rotateItem,
      onItemLayerChanged: _changeItemLayer,
      onItemRemoved: _removeItem,
      // Mid-gesture: update state so the stage repaints with the draft position.
      onItemChanged: (updated) {
        final old = _selectedItem;
        if (old != null) _updateItem(updated, old: old);
      },
      // Gesture ended: commit final position and queue autosave.
      onItemChangeEnd: (updated) {
        final old = _selectedItem;
        if (old != null) _updateItem(updated, old: old);
        _queueAutoSave();
      },
      currentCanvasScale: _currentCanvasScale,
    );
  }

  Widget _buildRoomHud() {
    return SafeArea(
      minimum: const EdgeInsets.all(8),
      child: Stack(
        children: [
          InventoryDrawer(
            visible: _inventoryVisible,
            inventory: _inventory,
            onShopPressed: () => context.go('/shop'),
            onClose: () => setState(() => _inventoryVisible = false),
          ),
          TopMenuDrawer(
            visible: _menuVisible,
            coins: _saveState!.coins,
            rooms: _saveState!.rooms,
            activeRoomIndex: _saveState!.activeRoomIndex,
            nextUnlockCost: _saveState!.nextUnlockCost,
            playerName: _playerName,
            playerLevel: _playerLevel,
            saving: _saving,
            inventoryVisible: _inventoryVisible,
            onToggleMenu: () {
              setState(() => _menuVisible = !_menuVisible);
            },
            onBack: _navigateBack,
            onGoToMenu: _navigateToMenu,
            onGoToCloset: _navigateToCloset,
            onCompetitionMode: _openCompetitionMode,
            onSettings: _openSettings,
            onRoomSelected: _switchRoom,
            onUnlockNextRoom: _unlockNextRoom,
            onToggleInventory: _toggleInventory,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _saveState == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFEEF7),
        body: Center(child: CircularProgressIndicator(color: RoomUi.accent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildRoomStage()),
          Positioned.fill(child: _buildRoomHud()),
        ],
      ),
    );
  }
}
