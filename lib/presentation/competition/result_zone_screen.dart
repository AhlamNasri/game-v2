import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:fashion_room_girls/data/models/achievement.dart';
import 'package:fashion_room_girls/data/models/character_customization.dart';
import 'package:fashion_room_girls/data/models/clothing_item.dart';
import 'package:fashion_room_girls/data/repositories/fashion_catalog.dart';
import 'package:fashion_room_girls/presentation/widgets/character_preview.dart';
import 'package:fashion_room_girls/theme/app_effects.dart';
import 'package:fashion_room_girls/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultZoneScreen extends StatefulWidget {
  final String roomId;

  const ResultZoneScreen({super.key, required this.roomId});

  @override
  State<ResultZoneScreen> createState() => _ResultZoneScreenState();
}

class _ResultZoneScreenState extends State<ResultZoneScreen> {
  bool _awardsGiven = false;
  double _awardOpacity = 0.0;
  String _awardText = '';
  List<Achievement> _newAchievements = [];
  late final ConfettiController _confettiController;
  bool _isReturning = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // ── Awards ─────────────────────────────────────────────

  Future<void> _giveAwards(List<QueryDocumentSnapshot> podiumList) async {
    if (_awardsGiven) return;
    _awardsGiven = true;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final rank =
        podiumList.indexWhere((d) => d.id == uid);
    if (rank == -1) return;

    final bool isWinner = rank == 0;
    int xpGain, coinGain;
    switch (rank) {
      case 0:
        xpGain = 50;
        coinGain = 100;
      case 1:
        xpGain = 30;
        coinGain = 60;
      case 2:
        xpGain = 20;
        coinGain = 40;
      default:
        xpGain = 10;
        coinGain = 20;
    }

    List<Achievement> newlyUnlocked = [];

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(uid);

      newlyUnlocked = await FirebaseFirestore.instance
          .runTransaction<List<Achievement>>((transaction) async {
        final snap = await transaction.get(userRef);
        final data = snap.data() ?? {};

        // ── XP / coins / level ──
        final currentXp = (data['xp'] as int? ?? 0);
        final newXp = currentXp + xpGain;
        final newLevel = ((newXp ~/ 100) + 1).clamp(1, 10);
        final newCoins = (data['coins'] as int? ?? 0) + coinGain;

        // ── Progression stats + win streak ──
        final played = (data['competitionsPlayed'] as int? ?? 0) + 1;
        final wins = (data['wins'] as int? ?? 0) + (isWinner ? 1 : 0);
        final prevStreak = data['currentStreak'] as int? ?? 0;
        final newStreak = isWinner ? prevStreak + 1 : 0;
        final bestStreak =
            (data['bestStreak'] as int? ?? 0) < newStreak
                ? newStreak
                : (data['bestStreak'] as int? ?? 0);

        transaction.update(userRef, {
          'xp': newXp,
          'coins': FieldValue.increment(coinGain),
          'level': newLevel,
          'competitionsPlayed': played,
          'wins': wins,
          'currentStreak': newStreak,
          'bestStreak': bestStreak,
        });

        // ── Achievements ──
        final stats = PlayerStats(
          wins: wins,
          competitionsPlayed: played,
          currentStreak: newStreak,
          bestStreak: bestStreak,
          level: newLevel,
          coins: newCoins,
          itemsOwned: (data['boughtItems'] as List?)?.length ?? 0,
        );
        final already =
            Set<String>.from(data['achievements'] as List? ?? const []);
        final earned = Achievements.earnedIds(stats);
        final fresh = earned.difference(already).toList();
        if (fresh.isNotEmpty) {
          transaction.update(userRef, {
            'achievements': FieldValue.arrayUnion(fresh),
          });
        }
        return fresh
            .map(Achievements.byId)
            .whereType<Achievement>()
            .toList();
      });
    } catch (_) {
      // Award write failure is non-fatal
    }

    if (!mounted) return;

    // Show award overlay
    setState(() {
      _awardText = '+${xpGain}xp  +$coinGain coins';
      _awardOpacity = 1.0;
      _newAchievements = newlyUnlocked;
    });

    if (isWinner) _confettiController.play();

    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) setState(() => _awardOpacity = 0.0);
  }

  // ── Cleanup + Return ───────────────────────────────────

  Future<void> _returnToMenu() async {
    if (_isReturning) return;
    setState(() => _isReturning = true);

    try {
      final outfitDocs = await FirebaseFirestore.instance
          .collection('lobbies')
          .doc(widget.roomId)
          .collection('submitted_outfits')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final d in outfitDocs.docs) {
        batch.delete(d.reference);
      }
      batch.delete(FirebaseFirestore.instance
          .collection('lobbies')
          .doc(widget.roomId));
      await batch.commit();
    } catch (_) {
      // Cleanup failure is non-fatal
    }

    if (mounted) context.go('/menu');
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        title: Text(
          "Results",
          style: AppTextStyles.heading
              .copyWith(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientSparkles(count: 20, color: AppColors.primaryLight),
          ),
          // Main content
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('lobbies')
                .doc(widget.roomId)
                .collection('submitted_outfits')
                .orderBy('votesCount', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                  ),
                );
              }

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "Loading results...",
                    style: AppTextStyles.body
                        .copyWith(color: const Color(0xFF704E52)),
                  ),
                );
              }

              final podiumList = snapshot.data!.docs;

              // Give awards once
              if (!_awardsGiven) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_awardsGiven) {
                    _giveAwards(podiumList);
                  }
                });
              }

              var winnerData =
                  podiumList[0].data() as Map<String, dynamic>;
              bool winnerIsBot = winnerData['isBot'] ?? false;
              int winnerVotes = winnerData['votesCount'] ?? 0;
              final winnerOutfitData =
                  (winnerData['outfitData'] as Map<String, dynamic>?) ?? {};
              String winnerName =
                  winnerData['username'] as String? ??
                      (winnerIsBot ? "Bot" : "Player");

              return SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Text(
                      "And the winner is",
                      style: AppTextStyles.subheading.copyWith(
                        color: const Color(0xFF704E52),
                        letterSpacing: 2,
                      ),
                    ),
                    // Winner card
                    Expanded(
                      flex: 5,
                      child: PulseGlow(
                        color: AppColors.coinGold,
                        borderRadius: BorderRadius.circular(24),
                        maxBlur: 34,
                        spread: 3,
                        child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryLight
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: _WinnerOutfitView(
                                outfitData: winnerOutfitData,
                                isBot: winnerIsBot,
                              ),
                            ),
                            const Positioned(
                              top: 12,
                              right: 12,
                              child: CircleAvatar(
                                backgroundColor: Colors.amber,
                                radius: 20,
                                child: Icon(Icons.emoji_events,
                                    color: Colors.white),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF704E52)
                                      .withValues(alpha: 0.85),
                                  borderRadius:
                                      const BorderRadius.only(
                                    bottomLeft: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                                child: Text(
                                  "$winnerName ($winnerVotes ⭐)",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                    ),
                    // Podium list
                    Expanded(
                      flex: 4,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20),
                        itemCount: podiumList.length,
                        itemBuilder: (context, index) {
                          var data = podiumList[index].data()
                              as Map<String, dynamic>;
                          bool isBot = data['isBot'] ?? false;
                          int votes = data['votesCount'] ?? 0;
                          String displayName =
                              data['username'] as String? ??
                                  (isBot
                                      ? "Bot"
                                      : "Player");

                          String rankPrefix = "${index + 1}. ";
                          if (index == 0) rankPrefix = "🥇 ";
                          if (index == 1) rankPrefix = "🥈 ";
                          if (index == 2) rankPrefix = "🥉 ";

                          return RevealIn(
                            delay: Duration(milliseconds: 120 * index),
                            child: Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4),
                            color: index == 0
                                ? const Color(0xFFFFF9E6)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Text(
                                rankPrefix,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              title: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: index == 0
                                      ? Colors.amber[800]
                                      : const Color(0xFF704E52),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight
                                      .withValues(alpha: 0.3),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "$votes ⭐",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF704E52),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          );
                        },
                      ),
                    ),
                    // Return button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: _isReturning ? null : _returnToMenu,
                        icon: _isReturning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2))
                            : const Icon(Icons.home),
                        label: const Text("Back to Menu",
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Award overlay (AnimatedOpacity)
          if (_awardText.isNotEmpty)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _awardOpacity,
                duration: const Duration(milliseconds: 500),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _awardText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Achievement unlock banners
          if (_newAchievements.isNotEmpty)
            Positioned(
              top: 132,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  for (var i = 0; i < _newAchievements.length; i++)
                    RevealIn(
                      delay: Duration(milliseconds: 400 + 220 * i),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AchievementBanner(_newAchievements[i]),
                      ),
                    ),
                ],
              ),
            ),
          // Confetti — top-centre
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: const [
                AppColors.primary,
                AppColors.coinGold,
                AppColors.accent,
                Colors.white,
                Colors.pinkAccent,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementBanner extends StatelessWidget {
  final Achievement achievement;
  const _AchievementBanner(this.achievement);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(achievement.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ACHIEVEMENT UNLOCKED',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WinnerOutfitView extends StatelessWidget {
  final Map<String, dynamic> outfitData;
  final bool isBot;

  const _WinnerOutfitView({required this.outfitData, required this.isBot});

  @override
  Widget build(BuildContext context) {
    if (isBot) {
      final botImage = outfitData['botImage'] as String? ??
          'assets/bots/avatar4.png';
      return Image.asset(
        botImage,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _ResultFallback(),
      );
    }

    final character = _characterFromOutfitData(outfitData);
    if (character == null) return const _ResultFallback();

    return LayoutBuilder(
      builder: (context, constraints) => CharacterPreview(
        character: character,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
      ),
    );
  }

  static CharacterCustomization? _characterFromOutfitData(
      Map<String, dynamic> data) {
    try {
      final gender =
          data['gender'] == 'boy' ? CharacterGender.boy : CharacterGender.girl;
      final skinTone = data['skinTone'] as String? ?? 'light';
      final hairAsset = data['hairAsset'] as String? ?? 'hair1';
      final rawIds = (data['outfitIds'] as Map<String, dynamic>?) ?? {};

      final outfit = <ClothingCategory, ClothingItem>{};
      for (final entry in rawIds.entries) {
        final category = ClothingCategory.values.firstWhere(
          (c) => c.name == entry.key,
          orElse: () => ClothingCategory.dresses,
        );
        final item = FashionCatalog.tryById(entry.value as String);
        if (item != null) outfit[category] = item;
      }

      return CharacterCustomization(
        gender: gender,
        skinTone: skinTone,
        hairAsset: hairAsset,
        faceAsset: '',
        outfit: outfit,
      );
    } catch (_) {
      return null;
    }
  }
}

class _ResultFallback extends StatelessWidget {
  const _ResultFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars, size: 60, color: Colors.amber),
          SizedBox(height: 8),
          Text(
            'No outfit',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
