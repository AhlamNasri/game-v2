import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live snapshot of the player's wallet/progression from `users/{uid}`.
class PlayerWallet {
  final int coins;
  final int level;
  final int xp;

  const PlayerWallet({this.coins = 0, this.level = 1, this.xp = 0});

  static const empty = PlayerWallet();

  factory PlayerWallet.fromMap(Map<String, dynamic>? data) {
    if (data == null) return empty;
    return PlayerWallet(
      coins: (data['coins'] ?? 0) as int,
      level: (data['level'] ?? 1) as int,
      xp: (data['xp'] ?? 0) as int,
    );
  }
}

/// Streams the current user's `users/{uid}` document. Emits `null` when signed
/// out (or anonymous with no doc). Re-subscribes automatically on auth change.
final userDocProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) async* {
  final auth = FirebaseAuth.instance;

  Stream<Map<String, dynamic>?> docStream(String uid) => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.data());

  await for (final user in auth.authStateChanges()) {
    if (user == null) {
      yield null;
    } else {
      yield* docStream(user.uid);
    }
  }
});

/// Live wallet (coins / level / xp). Defaults to empty while loading or guest.
final walletProvider = Provider.autoDispose<PlayerWallet>((ref) {
  return ref.watch(userDocProvider).maybeWhen(
        data: PlayerWallet.fromMap,
        orElse: () => PlayerWallet.empty,
      );
});

/// Live set of owned clothing item IDs (`users/{uid}.boughtItems`).
final ownedClothingProvider = Provider.autoDispose<Set<String>>((ref) {
  return ref.watch(userDocProvider).maybeWhen(
        data: (data) => {...?(data?['boughtItems'] as List?)?.cast<String>()},
        orElse: () => <String>{},
      );
});

/// Streams the current user's owned furniture IDs (`user_rooms/{uid}.inventory`).
final ownedFurnitureProvider =
    StreamProvider.autoDispose<Set<String>>((ref) async* {
  final auth = FirebaseAuth.instance;

  Stream<Set<String>> invStream(String uid) => FirebaseFirestore.instance
      .collection('user_rooms')
      .doc(uid)
      .snapshots()
      .map((snap) => {...?(snap.data()?['inventory'] as List?)?.cast<String>()});

  await for (final user in auth.authStateChanges()) {
    if (user == null) {
      yield <String>{};
    } else {
      yield* invStream(user.uid);
    }
  }
});
