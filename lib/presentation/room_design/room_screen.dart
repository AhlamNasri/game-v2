import 'package:flutter/material.dart';
import '../../data/services/room_service.dart';

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

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final RoomService _roomService = RoomService();

  List<String> inventory = [];
  List<RoomItem> placedItems = [];
  bool loading = true;
  RoomItem? _selectedItem;
  double _baseWidth = 120;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inv = await _roomService.loadInventory();
    final placed = await _roomService.loadRoom();
    setState(() {
      inventory = inv;
      placedItems = placed.map((e) => RoomItem.fromMap(e)).toList();
      loading = false;
    });
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
    }

    return Scaffold(
      body: Row(
        children: [
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
          ),
        ],
      ),
    );
  }
}
