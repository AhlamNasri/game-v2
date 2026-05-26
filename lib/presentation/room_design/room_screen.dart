import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'data/room_assets.dart';
import 'data/room_repository.dart';
import 'data/room_save_state.dart';
import 'models/inventory_item.dart';
import 'models/room_definition.dart';
import 'models/room_item.dart';
import 'theme/room_ui.dart';
import 'utils/room_item_sizing.dart';
import 'widgets/inventory_drawer.dart';
import 'widgets/room_stage.dart';
import 'widgets/top_menu_drawer.dart';

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

  int get _playerLevel => _saveState?.playerLevel ?? 5;

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
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Could not load room data.');
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

  Future<void> _unlockSecondRoom() async {
    final state = _saveState;
    if (state == null) return;

    if (state.rooms.length >= 2) {
      setState(() {
        _saveState = state.copyWith(activeRoomIndex: 1);
        _selectedItem = null;
      });
      return;
    }

    if (state.coins < RoomRepository.unlockSecondRoomCost) {
      _showMessage(
        'Need ${RoomRepository.unlockSecondRoomCost} coins to unlock Room 2',
      );
      return;
    }

    final rooms = [
      ...state.rooms,
      RoomDefinition(
        id: 'room_2',
        name: 'Room 2',
        background: _activeRoom.background,
        placedItems: const [],
      ),
    ];
    setState(() {
      _saveState = state.copyWith(
        rooms: rooms,
        activeRoomIndex: 1,
        coins: state.coins - RoomRepository.unlockSecondRoomCost,
      );
      _selectedItem = null;
    });
    await _saveRoom(silent: true);
    _showMessage('Room 2 unlocked');
  }

  void _switchRoom(int index) {
    final state = _saveState;
    if (state == null || index == state.activeRoomIndex) return;
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

  void _normalizeLayerOrder(List<RoomItem> items) {
    final ordered = List<RoomItem>.of(items)..sort(_compareLayerOrder);
    for (var index = 0; index < ordered.length; index++) {
      ordered[index].layer = index;
    }
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

    setState(() {
      _selectedItem = null;
      _activeRoom.placedItems.add(
        RoomItem(
          name: inventoryItem.name,
          asset: inventoryItem.asset,
          x: (sceneOffset.dx - itemWidth / 2).clamp(0, maxX).toDouble(),
          y: (sceneOffset.dy - itemWidth / 2).clamp(0, maxY).toDouble(),
          width: itemWidth,
          layer: _nextLayer(),
        ),
      );
      _saveState = state.copyWith(rooms: [...state.rooms]);
    });
    unawaited(_saveRoom(silent: true));
  }

  void _rotateItem(RoomItem item) {
    final state = _saveState;
    if (state == null) return;
    setState(() {
      _selectedItem = item;
      item.rotation = _normalizeRotation(item.rotation + math.pi / 12);
      _saveState = state.copyWith(rooms: [...state.rooms]);
    });
    unawaited(_saveRoom(silent: true));
  }

  void _changeItemLayer(RoomItem item, int direction) {
    final state = _saveState;
    if (state == null || _activeRoom.placedItems.length < 2) return;

    setState(() {
      _normalizeLayerOrder(_activeRoom.placedItems);
      final ordered = List<RoomItem>.of(_activeRoom.placedItems)
        ..sort((a, b) => a.layer.compareTo(b.layer));
      final index = ordered.indexOf(item);
      if (index == -1) return;

      final targetIndex = (index + direction)
          .clamp(0, ordered.length - 1)
          .toInt();
      if (targetIndex == index) return;

      final other = ordered[targetIndex];
      final layer = item.layer;
      item.layer = other.layer;
      other.layer = layer;
      _selectedItem = item;
      _saveState = state.copyWith(rooms: [...state.rooms]);
    });
    unawaited(_saveRoom(silent: true));
  }

  void _removeItem(RoomItem item) {
    final state = _saveState;
    if (state == null) return;
    setState(() {
      _activeRoom.placedItems.remove(item);
      _selectedItem = null;
      _saveState = state.copyWith(rooms: [...state.rooms]);
    });
    unawaited(_saveRoom(silent: true));
  }

  void _markRoomChanged() {
    final state = _saveState;
    if (state == null) return;
    setState(() {
      _saveState = state.copyWith(rooms: [...state.rooms]);
    });
  }

  void _toggleInventory() {
    setState(() {
      _inventoryVisible = !_inventoryVisible;
      if (_inventoryVisible) _menuVisible = false;
    });
  }

  void _navigateBack() {
    unawaited(_saveRoom(silent: true));
    if (context.canPop()) context.pop();
  }

  void _navigateToCloset() {
    unawaited(_saveRoom(silent: true));
    context.go('/dress-up');
  }

  void _openCompetitionMode() {
    _showMessage('Competition Mode coming soon');
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
      onItemChanged: _markRoomChanged,
      onItemChangeEnd: () {
        _markRoomChanged();
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
            playerName: _playerName,
            playerLevel: _playerLevel,
            saving: _saving,
            inventoryVisible: _inventoryVisible,
            onToggleMenu: () {
              setState(() => _menuVisible = !_menuVisible);
            },
            onBack: _navigateBack,
            onGoToCloset: _navigateToCloset,
            onCompetitionMode: _openCompetitionMode,
            onSettings: () => _showMessage('Settings screen coming soon'),
            onRoomSelected: _switchRoom,
            onUnlockSecondRoom: _unlockSecondRoom,
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
          // RoomStage owns the background — no duplicate layer here
          Positioned.fill(child: _buildRoomStage()),
          Positioned.fill(child: _buildRoomHud()),
        ],
      ),
    );
  }
}
