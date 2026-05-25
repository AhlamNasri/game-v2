import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class RoomItem {
  final String name;
  final String asset;
  double x;
  double y;
  double width;
  double rotation;

  RoomItem({
    required this.name,
    required this.asset,
    this.x = 100,
    this.y = 100,
    this.width = 120,
    this.rotation = 0,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'asset': asset,
    'x': x,
    'y': y,
    'width': width,
    'rotation': rotation,
  };

  factory RoomItem.fromMap(Map<String, dynamic> map) => RoomItem(
    name: (map['name'] ?? 'item').toString(),
    asset: (map['asset'] ?? '').toString(),
    x: ((map['x'] ?? 100) as num).toDouble(),
    y: ((map['y'] ?? 100) as num).toDouble(),
    width: ((map['width'] ?? 120) as num).toDouble(),
    rotation: ((map['rotation'] ?? 0) as num).toDouble(),
  );
}

class _RoomUi {
  static const accent = Color(0xFFE0549D);
  static const pillText = Color(0xFF5F2852);
  static const softPanel = Color(0xFFFFF7FB);
}

class RoomDefinition {
  final String id;
  final String name;
  final String background;
  final List<RoomItem> placedItems;

  RoomDefinition({
    required this.id,
    required this.name,
    required this.background,
    required List<RoomItem> placedItems,
  }) : placedItems = List<RoomItem>.of(placedItems);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'background': background,
    'placedItems': placedItems.map((item) => item.toMap()).toList(),
  };

  factory RoomDefinition.fromMap(Map<String, dynamic> map, int index) {
    final items = map['placedItems'] is List ? map['placedItems'] as List : [];
    return RoomDefinition(
      id: (map['id'] ?? 'room_${index + 1}').toString(),
      name: (map['name'] ?? 'Room ${index + 1}').toString(),
      background: (map['background'] ?? _RoomAssets.defaultBackground)
          .toString(),
      placedItems: items
          .whereType<Map>()
          .map((item) => RoomItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class InventoryItem {
  final String id;
  final String name;
  final String asset;
  final bool fromShop;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.asset,
    this.fromShop = false,
  });
}

class _RoomAssets {
  static const defaultBackground = 'room_assets/room_bg.jpeg';
  static const _imageExtensions = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];

  static Future<List<InventoryItem>> loadAvailableItems(
    List<String> ownedIds,
  ) async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allAssets = assetManifest.listAssets();
    final roomAssets =
        allAssets
            .where((path) => path.startsWith('room_assets/'))
            .where((path) => _imageExtensions.any(path.toLowerCase().endsWith))
            .where((path) => path != defaultBackground)
            .map(_itemFromAsset)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final byId = {for (final item in roomAssets) item.id: item};
    final owned = <InventoryItem>[];

    for (final id in ownedIds) {
      final normalized = _normalizeItemId(id);
      final bundled = byId[normalized];
      if (bundled != null) {
        owned.add(bundled);
      } else {
        owned.add(
          InventoryItem(
            id: normalized,
            name: _displayName(normalized),
            asset: id.contains('/') ? id : 'room_items_shop/$id.png',
            fromShop: true,
          ),
        );
      }
    }

    final merged = <String, InventoryItem>{};
    for (final item in [...roomAssets, ...owned]) {
      merged[item.id] = item;
    }

    return merged.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  static InventoryItem _itemFromAsset(String asset) {
    final fileName = asset.split('/').last;
    final id = _normalizeItemId(fileName);
    return InventoryItem(id: id, name: _displayName(id), asset: asset);
  }

  static String _normalizeItemId(String value) {
    final fileName = value.split('/').last;
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? fileName : fileName.substring(0, dot);
  }

  static String _displayName(String id) {
    return id
        .replaceAll(RegExp(r'[-_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _RoomRepository {
  static const unlockSecondRoomCost = 250;

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<_RoomSaveState> load() async {
    final user = currentUser;
    if (user == null) {
      return _RoomSaveState.guest();
    }

    final ref = _db.collection('user_rooms').doc(user.uid);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      final initial = _RoomSaveState.initial(user.uid);
      await ref.set(initial.toMap(), SetOptions(merge: true));
      return initial;
    }

    return _RoomSaveState.fromMap(user.uid, snapshot.data() ?? {});
  }

  Future<void> save(_RoomSaveState state) async {
    if (state.userId == 'guest') return;
    await _db
        .collection('user_rooms')
        .doc(state.userId)
        .set(state.toMap(), SetOptions(merge: true));
  }
}

class _RoomSaveState {
  final String userId;
  final List<String> inventory;
  final List<RoomDefinition> rooms;
  final int activeRoomIndex;
  final int coins;

  _RoomSaveState({
    required this.userId,
    required this.inventory,
    required this.rooms,
    required this.activeRoomIndex,
    required this.coins,
  });

  factory _RoomSaveState.initial(String userId) => _RoomSaveState(
    userId: userId,
    inventory: const [],
    rooms: [
      RoomDefinition(
        id: 'room_1',
        name: 'Room 1',
        background: _RoomAssets.defaultBackground,
        placedItems: const [],
      ),
    ],
    activeRoomIndex: 0,
    coins: 0,
  );

  factory _RoomSaveState.guest() => _RoomSaveState(
    userId: 'guest',
    inventory: const [],
    rooms: [
      RoomDefinition(
        id: 'room_1',
        name: 'Guest Room',
        background: _RoomAssets.defaultBackground,
        placedItems: const [],
      ),
    ],
    activeRoomIndex: 0,
    coins: 0,
  );

  factory _RoomSaveState.fromMap(String userId, Map<String, dynamic> data) {
    final rawRooms = data['rooms'] is List ? data['rooms'] as List : null;
    final legacyItems = data['placedItems'] is List
        ? data['placedItems'] as List
        : const [];
    final rooms = rawRooms == null || rawRooms.isEmpty
        ? [
            RoomDefinition(
              id: 'room_1',
              name: 'Room 1',
              background: _RoomAssets.defaultBackground,
              placedItems: legacyItems
                  .whereType<Map>()
                  .map(
                    (item) => RoomItem.fromMap(Map<String, dynamic>.from(item)),
                  )
                  .toList(),
            ),
          ]
        : rawRooms
              .whereType<Map>()
              .toList()
              .asMap()
              .entries
              .map(
                (entry) => RoomDefinition.fromMap(
                  Map<String, dynamic>.from(entry.value),
                  entry.key,
                ),
              )
              .toList();

    final active = ((data['activeRoomIndex'] ?? 0) as num).toInt();
    return _RoomSaveState(
      userId: userId,
      inventory: List<String>.from(data['inventory'] ?? const []),
      rooms: rooms,
      activeRoomIndex: active.clamp(0, rooms.length - 1),
      coins: ((data['coins'] ?? 0) as num).toInt(),
    );
  }

  _RoomSaveState copyWith({
    List<String>? inventory,
    List<RoomDefinition>? rooms,
    int? activeRoomIndex,
    int? coins,
  }) {
    return _RoomSaveState(
      userId: userId,
      inventory: inventory ?? this.inventory,
      rooms: rooms ?? this.rooms,
      activeRoomIndex: activeRoomIndex ?? this.activeRoomIndex,
      coins: coins ?? this.coins,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'inventory': inventory,
    'rooms': rooms.map((room) => room.toMap()).toList(),
    'activeRoomIndex': activeRoomIndex,
    'coins': coins,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with WidgetsBindingObserver {
  final _repository = _RoomRepository();
  final _viewportKey = GlobalKey();
  final _transformationController = TransformationController();

  List<InventoryItem> _inventory = [];
  _RoomSaveState? _saveState;
  RoomItem? _selectedItem;
  StreamSubscription<User?>? _authSubscription;
  bool _loading = true;
  bool _saving = false;
  bool _inventoryVisible = true; // FIX: inventory toggle state
  Size _stageSize = Size.zero;
  final Map<RoomItem, double> _gestureStartWidths = {};

  RoomDefinition get _activeRoom =>
      _saveState!.rooms[_saveState!.activeRoomIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      if (user == null && _saveState?.userId != 'guest') {
        await _saveRoom(silent: true);
      }
      await _loadData();
    });
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transformationController.dispose();
    _saveRoom(silent: true);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _saveRoom(silent: true);
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final saveState = await _repository.load();
      final inventory = await _RoomAssets.loadAvailableItems(
        saveState.inventory,
      );
      if (!mounted) return;
      setState(() {
        _saveState = saveState;
        _inventory = inventory;
        _selectedItem = null;
        _loading = false;
        _resetCanvasTransform();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Could not load room data.');
    }
  }

  Future<void> _saveRoom({bool silent = false}) async {
    final state = _saveState;
    if (state == null || _saving) return;
    _saving = true;
    try {
      await _repository.save(state);
      if (!silent && mounted) _showMessage('Room saved');
    } finally {
      _saving = false;
    }
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

    if (state.coins < _RoomRepository.unlockSecondRoomCost) {
      _showMessage(
        'Need ${_RoomRepository.unlockSecondRoomCost} coins to unlock Room 2',
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
        coins: state.coins - _RoomRepository.unlockSecondRoomCost,
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
      _resetCanvasTransform();
    });
    _saveRoom(silent: true);
  }

  void _resetCanvasTransform() {
    _transformationController.value = Matrix4.identity();
  }

  double _getItemWidth(String id) {
    switch (id) {
      case 'bed':
      case 'bed3':
        return 205;
      case 'sofa':
      case 'sofa2':
      case 'sofa3':
        return 220;
      case 'bath2':
      case 'bureau':
      case 'shelf':
        return 170;
      case 'chair':
      case 'minichair':
      case 'heartchair':
        return 110;
      case 'lamp':
      case 'lamp2':
      case 'lamp3':
      case 'lamp4':
      case 'green_lamps':
        return 90;
      case 'plant':
      case 'plant2':
      case 'miniplant':
        return 90;
      case 'clock':
        return 70;
      case 'tableau':
      case 'curtain2':
        return 130;
      default:
        return 120;
    }
  }

  void _addItem(InventoryItem inventoryItem, Offset globalOffset) {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final viewportOffset = box.globalToLocal(globalOffset);
    final sceneOffset = _transformationController.toScene(viewportOffset);
    final state = _saveState;
    if (state == null) return;

    final itemWidth = _getItemWidth(inventoryItem.id);
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
        ),
      );
      _saveState = state.copyWith(rooms: [...state.rooms]);
    });
    _saveRoom(silent: true);
  }

  void _rotateItem(RoomItem item) {
    setState(() {
      _selectedItem = item;
      item.rotation = (item.rotation + math.pi / 12) % (math.pi * 2);
    });
    _saveRoom(silent: true);
  }

  // FIX: Remove the selected item correctly, then trigger a save.
  void _removeItem(RoomItem item) {
    final state = _saveState;
    if (state == null) return;
    setState(() {
      _activeRoom.placedItems.remove(item);
      _selectedItem = null;
      // Propagate mutation so the save state reflects the change.
      _saveState = state.copyWith(rooms: [...state.rooms]);
    });
    _saveRoom(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _saveState == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFEEF7),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE0549D)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFEEF7),
      body: SafeArea(
        minimum: const EdgeInsets.all(10),
        child: Row(
          children: [
            // FIX: Wrap sidebar in AnimatedSize so it slides in/out smoothly.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _inventoryVisible
                  ? _InventorySidebar(
                      inventory: _inventory,
                      onShopPressed: () => context.go('/shop'),
                      onToggleInventory: () {
                        setState(() => _inventoryVisible = false);
                      },
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(child: _buildRoomStage(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomStage(BuildContext context) {
    return DragTarget<InventoryItem>(
      hitTestBehavior: HitTestBehavior.translucent,
      onAcceptWithDetails: (details) => _addItem(details.data, details.offset),
      builder: (context, candidate, rejected) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final stageSize = Size(constraints.maxWidth, constraints.maxHeight);
            _stageSize = stageSize;

            return SizedBox.expand(
              key: _viewportKey,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      panEnabled: false,
                      scaleEnabled: false,
                      minScale: 0.65,
                      maxScale: 3.0,
                      boundaryMargin: const EdgeInsets.all(180),
                      clipBehavior: Clip.none,
                      child: SizedBox(
                        width: stageSize.width,
                        height: stageSize.height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    setState(() => _selectedItem = null),
                                child: Image.asset(
                                  _activeRoom.background,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
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
                                        const Color(
                                          0xFF5C2D53,
                                        ).withValues(alpha: 0.12),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: IgnorePointer(
                                child: Container(
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE8D9DD,
                                    ).withValues(alpha: 0.92),
                                    border: const Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFBFA7AE),
                                        width: 2,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ..._activeRoom.placedItems.map(_buildPlacedItem),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // HUD
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: _TopHud(
                      coins: _saveState!.coins,
                      rooms: _saveState!.rooms,
                      activeRoomIndex: _saveState!.activeRoomIndex,
                      saving: _saving,
                      inventoryVisible: _inventoryVisible,
                      onBack: () {
                        _saveRoom(silent: true);
                        if (context.canPop()) context.pop();
                      },
                      onSave: _saveRoom,
                      onSettings: () =>
                          _showMessage('Settings screen coming soon'),
                      onRoomSelected: _switchRoom,
                      onUnlockSecondRoom: _unlockSecondRoom,
                      // FIX: Toggle inventory visibility.
                      onToggleInventory: () {
                        setState(() => _inventoryVisible = !_inventoryVisible);
                      },
                    ),
                  ),
                  // Drop target highlight
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

  Widget _buildPlacedItem(RoomItem item) {
    final isSelected = _selectedItem == item;
    const toolbarWidth = 132.0;
    const toolbarHeight = 40.0;
    const toolbarGap = 8.0;
    final toolbarExtra = isSelected
        ? math.max(0.0, (toolbarWidth - item.width) / 2)
        : 0.0;
    final left = math.max(0.0, item.x - toolbarExtra);
    final top = isSelected
        ? math.max(0.0, item.y - toolbarHeight - toolbarGap)
        : item.y;
    final itemLeft = item.x - left;
    final itemTop = item.y - top;
    final touchWidth = isSelected
        ? math.max(item.width + toolbarExtra * 2, toolbarWidth)
        : item.width;
    final touchHeight = isSelected ? itemTop + item.width + 8 : item.width;

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: touchWidth,
        height: touchHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isSelected)
              Positioned(
                left: (touchWidth - toolbarWidth) / 2,
                top: 0,
                child: _ItemToolbar(
                  onMove: () => setState(() => _selectedItem = item),
                  onRotate: () => _rotateItem(item),
                  onDelete: () => _removeItem(item),
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
                  onTap: () =>
                      setState(() => _selectedItem = isSelected ? null : item),
                  onScaleStart: (_) {
                    _gestureStartWidths[item] = item.width;
                    setState(() => _selectedItem = item);
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      if (details.pointerCount >= 2) {
                        final startWidth =
                            _gestureStartWidths[item] ?? item.width;
                        item.width = (startWidth * details.scale)
                            .clamp(42, 420)
                            .toDouble();
                      } else {
                        final maxX = (_stageSize.width - item.width)
                            .clamp(0, double.infinity)
                            .toDouble();
                        final maxY = (_stageSize.height - item.width)
                            .clamp(0, double.infinity)
                            .toDouble();
                        item.x = (item.x + details.focalPointDelta.dx)
                            .clamp(0, maxX)
                            .toDouble();
                        item.y = (item.y + details.focalPointDelta.dy)
                            .clamp(0, maxY)
                            .toDouble();
                      }
                    });
                  },
                  onScaleEnd: (_) {
                    _gestureStartWidths.remove(item);
                    _saveRoom(silent: true);
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
}

class _ItemToolbar extends StatelessWidget {
  final VoidCallback onMove;
  final VoidCallback onRotate;
  final VoidCallback onDelete;

  const _ItemToolbar({
    required this.onMove,
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
          border: Border.all(color: _RoomUi.accent.withValues(alpha: 0.42)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniIconButton(
              icon: Icons.open_with,
              tooltip: 'Move',
              onPressed: onMove,
            ),
            const SizedBox(width: 6),
            _MiniIconButton(
              icon: Icons.rotate_right,
              tooltip: 'Rotate',
              onPressed: onRotate,
            ),
            const SizedBox(width: 6),
            _MiniIconButton(
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

class _InventorySidebar extends StatelessWidget {
  final List<InventoryItem> inventory;
  final VoidCallback onShopPressed;
  final VoidCallback onToggleInventory;

  const _InventorySidebar({
    required this.inventory,
    required this.onShopPressed,
    required this.onToggleInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 166,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_RoomUi.softPanel, Color(0xFFFFD7EA)],
        ),
        border: Border(right: BorderSide(color: Color(0xFFF2A6CA), width: 2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              children: [
                Expanded(child: _SidebarShopButton(onPressed: onShopPressed)),
                const SizedBox(width: 6),
                _RoundIconButton(
                  icon: Icons.keyboard_double_arrow_left,
                  tooltip: 'Hide inventory',
                  color: _RoomUi.accent,
                  onPressed: onToggleInventory,
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
                  primary: false,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 4, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        color: _RoomUi.accent,
        shape: const StadiumBorder(),
        elevation: 4,
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

class _TopHud extends StatelessWidget {
  final int coins;
  final List<RoomDefinition> rooms;
  final int activeRoomIndex;
  final bool saving;
  final bool inventoryVisible; // FIX: new param
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onSettings;
  final ValueChanged<int> onRoomSelected;
  final VoidCallback onUnlockSecondRoom;
  final VoidCallback onToggleInventory; // FIX: new param

  const _TopHud({
    required this.coins,
    required this.rooms,
    required this.activeRoomIndex,
    required this.saving,
    required this.inventoryVisible,
    required this.onBack,
    required this.onSave,
    required this.onSettings,
    required this.onRoomSelected,
    required this.onUnlockSecondRoom,
    required this.onToggleInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          color: _RoomUi.accent,
          onPressed: onBack,
        ),
        _StatusPill(
          icon: Icons.monetization_on,
          label: '$coins',
          color: _RoomUi.accent,
        ),
        for (var index = 0; index < rooms.length; index++)
          ChoiceChip(
            selected: index == activeRoomIndex,
            label: Text(rooms[index].name),
            avatar: const Icon(Icons.meeting_room, size: 16),
            onSelected: (_) => onRoomSelected(index),
            selectedColor: _RoomUi.accent,
            backgroundColor: Colors.white.withValues(alpha: 0.94),
            shape: const StadiumBorder(),
            labelStyle: const TextStyle(
              color: _RoomUi.pillText,
              fontWeight: FontWeight.w800,
            ),
          ),
        if (rooms.length < 2)
          ActionChip(
            avatar: const Icon(Icons.add_home, size: 18),
            label: const Text('Unlock Room 2'),
            onPressed: onUnlockSecondRoom,
            backgroundColor: _RoomUi.accent,
            shape: const StadiumBorder(),
            labelStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        _RoundIconButton(
          icon: saving ? Icons.cloud_sync : Icons.cloud_done,
          tooltip: 'Save room',
          color: _RoomUi.accent,
          onPressed: onSave,
        ),
        // FIX: Inventory toggle button – icon reflects current visibility state.
        _RoundIconButton(
          icon: inventoryVisible
              ? Icons.inventory_2
              : Icons.inventory_2_outlined,
          tooltip: inventoryVisible ? 'Hide inventory' : 'Show inventory',
          color: _RoomUi.accent,
          onPressed: onToggleInventory,
        ),
        _RoundIconButton(
          icon: Icons.settings,
          tooltip: 'Settings',
          color: _RoomUi.accent,
          onPressed: onSettings,
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF633355),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _RoomUi.accent,
        shape: const StadiumBorder(),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: SizedBox(
            width: 46,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _RoomUi.accent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
