import 'package:cloud_firestore/cloud_firestore.dart';

class RoomService {
  final _db = FirebaseFirestore.instance;
  final String docId = 'HfByowGtmdNWoSvmnNFU';

  // Load user's owned items (inventory)
  Future<List<String>> loadInventory() async {
    final doc = await _db.collection('user_rooms').doc(docId).get();
    final data = doc.data();
    if (data == null) return [];
    return List<String>.from(data['inventory'] ?? []);
  }

  // Load placed items on room canvas
  Future<List<Map<String, dynamic>>> loadRoom() async {
    final doc = await _db.collection('user_rooms').doc(docId).get();
    final data = doc.data();
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data['placedItems'] ?? []);
  }

  // Save placed items
  Future<void> saveRoom(List<Map<String, dynamic>> placedItems) async {
    await _db.collection('user_rooms').doc(docId).update({
      'placedItems': placedItems,
    });
  }
}