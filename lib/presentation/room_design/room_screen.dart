import 'dart:async';
import 'dart:math' as math;

import 'package:fashion_room_girls/data/services/lobbyService.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

// class RoomItem {
//   final String name;
//   final String asset; // full filename, e.g. "bed.png", "photo.jpeg", "bg.webp"
//   double x;
//   double y;
//   double width;

//   RoomItem({
//     required this.name,
//     required this.asset,
//     this.x = 100,
//     this.y = 100,
//     this.width = 120,
//   });

//   Map<String, dynamic> toMap() => {
//     'name': name,
//     'asset': asset,
//     'x': x,
//     'y': y,
//     'width': width,
//   };

//   factory RoomItem.fromMap(Map<String, dynamic> map) => RoomItem(
//     name: map['name'],
//     asset: map['asset'],
//     x: (map['x'] as num).toDouble(),
//     y: (map['y'] as num).toDouble(),
//     width: (map['width'] as num).toDouble(),
//   );
// }

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
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) async {
        if (user == null && _saveState?.userId != 'guest') {
          await _saveRoom(silent: true);
        }
        await _loadData();
      },
    );
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
    // Always capture _saveState at call time so we save the latest version
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

  /// Replaces the active room with [updatedRoom] and returns the new full
  /// save state. Does NOT call setState — callers do that.
  RoomSaveState _withUpdatedActiveRoom(
    RoomSaveState state,
    RoomDefinition updatedRoom,
  ) {
    final updatedRooms = List<RoomDefinition>.of(state.rooms);
    updatedRooms[state.activeRoomIndex] = updatedRoom;
    return state.copyWith(rooms: updatedRooms);
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
    final stageWidth =
        _stageSize.width == 0 ? box.size.width : _stageSize.width;
    final stageHeight =
        _stageSize.height == 0 ? box.size.height : _stageSize.height;
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

    // Build an entirely new RoomDefinition — no mutation of existing lists
    final updatedRoom = RoomDefinition(
      id: _activeRoom.id,
      name: _activeRoom.name,
      background: _activeRoom.background,
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

    // Replace the matching item with a rotated copy — no mutation
    final updatedItems = _activeRoom.placedItems.map((i) {
      if (i == item) {
        return RoomItem(
          name: i.name,
          asset: i.asset,
          x: i.x,
          y: i.y,
          width: i.width,
          rotation: _normalizeRotation(i.rotation + math.pi / 12),
          layer: i.layer,
        );
      }
      return i;
    }).toList();

    final updatedRoom = RoomDefinition(
      id: _activeRoom.id,
      name: _activeRoom.name,
      background: _activeRoom.background,
      placedItems: updatedItems,
    );

    setState(() {
      _saveState = _withUpdatedActiveRoom(state, updatedRoom);
      // Keep the rotated copy selected
      _selectedItem = updatedItems.firstWhere(
        (i) => i.asset == item.asset && i.x == item.x && i.y == item.y,
        orElse: () => updatedItems.last,
      );
    });
    _queueAutoSave();
  }

  void _changeItemLayer(RoomItem item, int direction) {
    final state = _saveState;
    if (state == null || _activeRoom.placedItems.length < 2) return;

    // Work on a copy, normalize, then swap layers
    final items = _activeRoom.placedItems.map((i) => RoomItem(
      name: i.name, asset: i.asset, x: i.x, y: i.y,
      width: i.width, rotation: i.rotation, layer: i.layer,
    )).toList();

    // Normalize layer order on the copies
    final ordered = List<RoomItem>.of(items)..sort(_compareLayerOrder);
    for (var idx = 0; idx < ordered.length; idx++) {
      ordered[idx].layer = idx;
    }

    final index = ordered.indexWhere(
      (i) => i.asset == item.asset && i.x == item.x && i.y == item.y,
    );
    if (index == -1) return;

    final targetIndex = (index + direction).clamp(0, ordered.length - 1).toInt();
    if (targetIndex == index) return;

    final other = ordered[targetIndex];
    final layer = ordered[index].layer;
    ordered[index].layer = other.layer;
    other.layer = layer;

    final updatedRoom = RoomDefinition(
      id: _activeRoom.id,
      name: _activeRoom.name,
      background: _activeRoom.background,
      placedItems: items,
    );

    setState(() {
      _saveState = _withUpdatedActiveRoom(state, updatedRoom);
      _selectedItem = ordered[index];
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
      placedItems: _activeRoom.placedItems.where((i) => i != item).toList(),
    );

    setState(() {
      _saveState = _withUpdatedActiveRoom(state, updatedRoom);
      _selectedItem = null;
    });
    _queueAutoSave();
  }

  /// Called by RoomStage when an item is dragged (position mutated in-place
  /// by the stage widget). We rebuild the state so _saveState reflects the
  /// latest positions before the autosave fires.
  void _markRoomChanged() {
    final state = _saveState;
    if (state == null) return;

    // Copy current items (with their already-mutated x/y from the stage)
    // into a fresh RoomDefinition so toMap() captures the latest positions.
    final updatedRoom = RoomDefinition(
      id: _activeRoom.id,
      name: _activeRoom.name,
      background: _activeRoom.background,
      placedItems: List<RoomItem>.of(_activeRoom.placedItems),
    );

    setState(() {
      _saveState = _withUpdatedActiveRoom(state, updatedRoom);
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

<<<<<<< HEAD
  Future<void> _openCompetitionMode() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // 🚨 VÉRIF MAGIQUE : Si pas connecté OU si le compte est anonyme (Guest)
    // On le redirige direct vers le login avant même d'ouvrir le loader
    if (currentUser == null || currentUser.isAnonymous) {
      print(
        "Accès refusé : Utilisateur déconnecté ou Anonyme -> Redirection Login",
      );
      if (context.mounted) {
        context.push('/login?roomId=none');
      }
      return; // On stoppe l'exécution ici !
    }

    // 2. Si on arrive ici, l'utilisateur a un VRAI compte officiel.
    // On peut afficher l'indicateur de chargement visuel pour le matchmaking.
=======
 Future<void> _openCompetitionMode() async {
    // _showMessage('Competition Mode coming soon');
>>>>>>> upstream/develop
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
<<<<<<< HEAD
      // 3. On récupère les infos locales ou par défaut depuis SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // On utilise directement l'uid de Firebase puisqu'on est sûr qu'il est connecté
      String myUid = currentUser.uid;

      // Récupération du pseudo, de l'avatar et du niveau sauvegardés localement
=======
      // 2. On récupère les infos locales ou par défaut depuis SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Récupération de l'ID utilisateur (Firebase Auth ou SharedPreferences)
      final User? currentUser = FirebaseAuth.instance.currentUser;
      String myUid =
          currentUser?.uid ?? prefs.getString('uid') ?? "uid_inconnu";

      // Récupération du pseudo et de l'avatar sauvegardés localement
>>>>>>> upstream/develop
      String myNickname = prefs.getString('user_nickname') ?? "Joueur";
      String myAvatarId = prefs.getString('user_avatarId') ?? "default_avatar";
      int myLevel =
          prefs.getInt('user_level') ??
          1; // Niveau dynamique (ou laisse 1 par défaut)

<<<<<<< HEAD
      // 4. Appel du service de matchmaking avec la structure complète 📦
=======
      // 🚨 Si l'utilisateur n'est pas connecté du tout sur Firebase, on le redirige vers le login d'abord
      if (currentUser == null) {
        if (context.mounted) Navigator.pop(context); // Ferme le loader
        if (context.mounted) context.push('/login?roomId=none');
        return;
      }

      // 3. Appel du service de matchmaking avec la nouvelle structure complète 📦
>>>>>>> upstream/develop
      String roomId = await LobbyService().findOrCreateLobby(
        currentUserId: myUid,
        currentUserNickname: myNickname,
        currentUserAvatarId: myAvatarId,
        userLevel: myLevel,
      );

<<<<<<< HEAD
      // 5. On ferme le dialogue de chargement dès que la salle est trouvée/créée
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 6. Direction le Lobby en direct ! 🚀
      print("Profil officiel injecté -> Direction le Lobby : $roomId");
=======
      // 4. On ferme le dialogue de chargement
      if (context.mounted) Navigator.pop(context);

      // 5. Direction le Lobby direct ! 🚀
      print("Profil complet injecté -> Direction le Lobby : $roomId");
>>>>>>> upstream/develop
      if (context.mounted) {
        // Note : Utilise widget.lobbyId dans ton LobbyScreen pour lire la variable roomId passée ici
        context.push('/lobby?roomId=$roomId');
      }
    } catch (error) {
      // Fermer le chargement en cas de crash ou problème réseau
      if (context.mounted) {
        Navigator.pop(context);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible de trouver une salle : $error")),
        );
      }
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
          Positioned.fill(child: _buildRoomStage()),
          Positioned.fill(child: _buildRoomHud()),
        ],
      ),
    );
  }
}