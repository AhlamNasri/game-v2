import 'package:flutter/services.dart';

import '../models/inventory_item.dart';

class RoomAssets {
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
