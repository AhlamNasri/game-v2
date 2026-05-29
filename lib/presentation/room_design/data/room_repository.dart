import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'room_save_state.dart';

class RoomRepository {
  static const unlockSecondRoomCost = 250;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RoomRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<RoomSaveState> load() async {
    final user = currentUser;
    if (user == null) return RoomSaveState.guest();

    final results = await Future.wait([
      _db.collection('user_rooms').doc(user.uid).get(),
      _db.collection('users').doc(user.uid).get(),
    ]);

    final roomSnap = results[0];
    final userSnap = results[1];
    final userData = userSnap.data() ?? {};
    final coins = ((userData['coins'] ?? 0) as num).toInt();
    final playerLevel = ((userData['level'] ?? 1) as num).toInt();

    if (!roomSnap.exists) {
      final initial = RoomSaveState.initial(
        user.uid,
      ).copyWith(coins: coins, playerLevel: playerLevel);
      await _db
          .collection('user_rooms')
          .doc(user.uid)
          .set(initial.toMap(), SetOptions(merge: true));
      return initial;
    }

    return RoomSaveState.fromMap(
      user.uid,
      roomSnap.data() ?? {}, 
       userData,  // ← add this
    ).copyWith(coins: coins, playerLevel: playerLevel);
  }

  Future<void> save(RoomSaveState state) async {
    if (state.userId == 'guest') return;
    await _db
        .collection('user_rooms')
        .doc(state.userId)
        .set(state.toMap(), SetOptions(merge: true));
  }
}
