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
    if (user == null) {
      return RoomSaveState.guest();
    }

    final ref = _db.collection('user_rooms').doc(user.uid);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      final initial = RoomSaveState.initial(user.uid);
      await ref.set(initial.toMap(), SetOptions(merge: true));
      return initial;
    }

    return RoomSaveState.fromMap(user.uid, snapshot.data() ?? {});
  }

  Future<void> save(RoomSaveState state) async {
    if (state.userId == 'guest') return;
    await _db
        .collection('user_rooms')
        .doc(state.userId)
        .set(state.toMap(), SetOptions(merge: true));
  }
}
