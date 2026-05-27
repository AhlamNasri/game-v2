import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

<<<<<<< HEAD
class RoomItem {
  final String name;
  final String asset; // full filename, e.g. "bed.png", "photo.jpeg", "bg.webp"
  double x;
  double y;
  double width;

  RoomItem({
    required this.name,
    required this.asset,
    this.x = 100,
    this.y = 100,
    this.width = 120,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'asset': asset,
    'x': x,
    'y': y,
    'width': width,
  };

  factory RoomItem.fromMap(Map<String, dynamic> map) => RoomItem(
    name: map['name'],
    asset: map['asset'],
    x: (map['x'] as num).toDouble(),
    y: (map['y'] as num).toDouble(),
    width: (map['width'] as num).toDouble(),
  );
}

/// Returns the full asset path for an item name.
/// It checks a priority list of extensions and falls back to the
/// name itself if it already contains an extension.
String _resolveAssetPath(String itemName) {
  // If the inventory already stores full filenames (e.g. "bed.jpeg"), use as-is.
  if (itemName.contains('.')) {
    return 'room_assets/$itemName';
  }
  // Otherwise fall back to the extension-priority helper.
  // At runtime Flutter will throw if the asset doesn't exist, so keep your
  // pubspec.yaml assets list up-to-date with the actual files.
  return 'room_assets/$itemName.png'; // default; see _AssetImage below
}

/// A widget that tries multiple extensions in order and renders the first one
/// that exists, showing a placeholder on failure.
class _AnyExtensionImage extends StatelessWidget {
  final String itemName;
  final double width;
  final BoxFit fit;

  const _AnyExtensionImage({
    required this.itemName,
    required this.width,
    this.fit = BoxFit.contain,
  });

  static const _extensions = ['png', 'jpg', 'jpeg', 'webp', 'gif'];

  /// If itemName already carries an extension just use it directly.
  bool get _hasExtension => itemName.contains('.');

  @override
  Widget build(BuildContext context) {
    if (_hasExtension) {
      return Image.asset(
        'room_assets/$itemName',
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    // Build a chain of Image.asset widgets, each falling back to the next
    // extension on error.
    return _FallbackImage(
      basePath: 'room_assets/$itemName',
      extensions: _extensions,
      width: width,
      fit: fit,
    );
  }

  Widget _placeholder() => SizedBox(
    width: width,
    height: width,
    child: const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.grey),
    ),
  );
}

/// Tries [extensions] one by one, falling through on asset-load errors.
class _FallbackImage extends StatefulWidget {
  final String basePath;
  final List<String> extensions;
  final double width;
  final BoxFit fit;

  const _FallbackImage({
    required this.basePath,
    required this.extensions,
    required this.width,
    required this.fit,
  });

  @override
  State<_FallbackImage> createState() => _FallbackImageState();
}

class _FallbackImageState extends State<_FallbackImage> {
  int _extIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_extIndex >= widget.extensions.length) {
      return SizedBox(
        width: widget.width,
        height: widget.width,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      );
    }

    final path = '${widget.basePath}.${widget.extensions[_extIndex]}';
    return Image.asset(
      path,
      width: widget.width,
      fit: widget.fit,
      errorBuilder: (_, __, ___) {
        // Try the next extension on the next frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _extIndex++);
        });
        return const SizedBox.shrink();
      },
    );
  }
}

// ---------------------------------------------------------------------------
=======
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
>>>>>>> upstream/develop

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
<<<<<<< HEAD
  }

  Future<void> _saveRoom() async {
    await _roomService.saveRoom(placedItems.map((e) => e.toMap()).toList());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Room saved! 🎀')));
  }

  double _getItemWidth(String itemName) {
    // Strip extension for the size-lookup so "bed.jpeg" and "bed" both work.
    final base = itemName.contains('.')
        ? itemName.substring(0, itemName.lastIndexOf('.'))
        : itemName;
    switch (base) {
      case 'bed':
        return 200;
      case 'sofa':
        return 220;
      case 'chair':
        return 100;
      case 'lamp':
        return 90;
      case 'plant':
        return 90;
      case 'clock':
        return 70;
      case 'tableau':
        return 110;
      case 'deco':
        return 80;
      default:
        return 120;
    }
  }

  /// Derives the asset path to store on a newly placed RoomItem.
  /// Inventory entries may be bare names ("bed") or full filenames ("bed.jpeg").
  String _assetPathFor(String itemName) {
    if (itemName.contains('.')) return 'room_assets/$itemName';
    return 'room_assets/$itemName.png'; // will be resolved at display time
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
=======
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
>>>>>>> upstream/develop
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
<<<<<<< HEAD
          // LEFT: vertical inventory panel
          Container(
            width: 90,
            color: Colors.pink[50],
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: inventory.length,
                    itemBuilder: (context, index) {
                      final itemName = inventory[index];
                      return Draggable<String>(
                        data: itemName,
                        feedback: _AnyExtensionImage(
                          itemName: itemName,
                          width: 80,
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _AnyExtensionImage(
                            itemName: itemName,
                            width: 70,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              _AnyExtensionImage(itemName: itemName, width: 70),
                              Text(
                                itemName,
                                style: const TextStyle(fontSize: 9),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // RIGHT: room canvas
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                final box = context.findRenderObject() as RenderBox;
                final localOffset = box.globalToLocal(details.offset);
                setState(() {
                  _selectedItem = null;
                  placedItems.add(
                    RoomItem(
                      name: details.data,
                      asset: _assetPathFor(details.data),
                      x: localOffset.dx - 90,
                      y: localOffset.dy,
                      width: _getItemWidth(details.data),
                    ),
                  );
                });
              },
              builder: (context, candidate, rejected) {
                return Stack(
                  children: [
                    // Background — tap to deselect
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedItem = null;
                        });
                      },
                      child: Image.asset(
                        'room_assets/room_bg.jpeg', // already has extension ✓
                        fit: BoxFit.fill,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),

                    // Save button
                    Positioned(
                      top: 40,
                      right: 16,
                      child: ElevatedButton.icon(
                        onPressed: _saveRoom,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[200],
                        ),
                      ),
                    ),

                    // Placed items
                    ...placedItems.map((item) {
                      final isSelected = _selectedItem == item;
                      return Positioned(
                        left: item.x,
                        top: item.y,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _selectedItem = isSelected ? null : item;
                                });
                              },
                              onScaleStart: (_) {
                                _baseWidth = item.width;
                              },
                              onScaleUpdate: (details) {
                                setState(() {
                                  item.x += details.focalPointDelta.dx;
                                  item.y += details.focalPointDelta.dy;
                                  if (details.pointerCount >= 2) {
                                    item.width = (_baseWidth * details.scale)
                                        .clamp(40, 400);
                                  }
                                });
                              },
                              child: Container(
                                decoration: isSelected
                                    ? BoxDecoration(
                                        border: Border.all(
                                          color: Colors.pink,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      )
                                    : null,
                                // Use the stored asset path directly —
                                // it already includes the correct extension.
                                child: Image.asset(
                                  item.asset,
                                  width: item.width,
                                  errorBuilder: (_, __, ___) =>
                                      _AnyExtensionImage(
                                        itemName: item.name,
                                        width: item.width,
                                      ),
                                ),
                              ),
                            ),

                            // ❌ delete button
                            if (isSelected)
                              Positioned(
                                top: -14,
                                right: -14,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      placedItems.remove(item);
                                      _selectedItem = null;
                                    });
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
=======
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
>>>>>>> upstream/develop
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
=======

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
>>>>>>> upstream/develop
}
