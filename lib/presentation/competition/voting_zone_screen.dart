import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/character_customization.dart';
import '../../data/models/clothing_item.dart';
import '../../data/repositories/fashion_catalog.dart';
import '../../data/services/lobby_service.dart';
import '../../theme/app_effects.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_widgets.dart';
import '../widgets/character_preview.dart';

class VotingZoneScreen extends StatefulWidget {
  final String roomId;
  final String currentUserId;

  const VotingZoneScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
  });

  @override
  State<VotingZoneScreen> createState() => _VotingZoneScreenState();
}

class _VotingZoneScreenState extends State<VotingZoneScreen> {
  final LobbyService _lobbyService = LobbyService();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _lobbySubscription;
  Timer? _ticker;
  DateTime? _votingEndsAt;

  bool _hasVoted = false;
  bool _isVoting = false;
  bool _isFinalizing = false;
  bool _navigating = false;

  // ValueNotifier isolates timer rebuilds to a single tiny widget —
  // the rest of the Scaffold (StreamBuilder, grid) never rebuilds per-second.
  final _secondsNotifier =
      ValueNotifier<int>(LobbyService.votingDuration.inSeconds);

  @override
  void initState() {
    super.initState();
    _listenToLobby();
  }

  @override
  void dispose() {
    _lobbySubscription?.cancel();
    _ticker?.cancel();
    _secondsNotifier.dispose();
    super.dispose();
  }

  void _listenToLobby() {
    if (widget.roomId.trim().isEmpty) return;

    _lobbySubscription = FirebaseFirestore.instance
        .collection('lobbies')
        .doc(widget.roomId)
        .snapshots()
        .listen(_handleLobbySnapshot);
  }

  void _handleLobbySnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!mounted) return;
    final data = snapshot.data();
    if (data == null) return;

    final status = data['status'] as String? ?? 'waiting';
    if (status == 'results' || status == 'completed') {
      _goToResults();
      return;
    }

    final votedIds = <String>{
      ...?((data['votedPlayerIds'] as List?)?.map((e) => e.toString()))
    };
    final votingEndsAt = data['votingEndsAt'];

    final newHasVoted = votedIds.contains(widget.currentUserId);
    final newEndsAt =
        votingEndsAt is Timestamp ? votingEndsAt.toDate() : null;

    // Only rebuild the parent widget when meaningful state actually changes.
    if (newHasVoted != _hasVoted || newEndsAt != _votingEndsAt) {
      setState(() {
        _hasVoted = newHasVoted;
        _votingEndsAt = newEndsAt;
      });
    }
    _syncTicker();
  }

  void _syncTicker() {
    _ticker ??=
        Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    if (!mounted || _navigating) return;
    final endsAt = _votingEndsAt;
    if (endsAt == null) return;

    final remaining = endsAt.difference(DateTime.now()).inSeconds;
    final seconds =
        remaining.clamp(0, LobbyService.votingDuration.inSeconds);
    _secondsNotifier.value = seconds; // no setState — only the timer badge rebuilds

    if (seconds == 0) {
      _ticker?.cancel();
      unawaited(_autoVoteAndNavigate());
    }
  }

  Future<void> _autoVoteAndNavigate() async {
    if (_navigating) return;
    try {
      await _lobbyService.completeVotingIfReady(
        lobbyId: widget.roomId,
        requestedByUserId: widget.currentUserId,
        force: true,
      );
    } catch (e) {
      debugPrint('completeVotingIfReady error: $e');
    }
    _goToResults();
  }

  Future<void> _voteForOutfit(String opponentId) async {
    if (_hasVoted || _isVoting || _isFinalizing) return;
    setState(() => _isVoting = true);

    try {
      final accepted = await _lobbyService.castVote(
        lobbyId: widget.roomId,
        voterId: widget.currentUserId,
        targetUserId: opponentId,
      );

      if (!mounted) return;
      setState(() {
        _hasVoted = true;
        _isVoting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepted
                ? 'Vote counted! Preparing results...'
                : 'Already voted.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );

      unawaited(_completeVoting(force: false));
      // Navigate immediately after a brief delay so the snackbar is visible.
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _goToResults();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVoting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote error: $e')),
      );
    }
  }

  Future<void> _completeVoting({required bool force}) async {
    if (_isFinalizing || _navigating) return;
    setState(() => _isFinalizing = true);
    try {
      await _lobbyService.completeVotingIfReady(
        lobbyId: widget.roomId,
        requestedByUserId: widget.currentUserId,
        force: force,
      );
    } catch (e) {
      debugPrint('completeVotingIfReady error: $e');
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  void _goToResults() {
    if (_navigating) return;
    _navigating = true;
    _ticker?.cancel();
    _lobbySubscription?.cancel();
    if (mounted) {
      context.go(
        '/result-zone'
        '?roomId=${widget.roomId}'
        '&currentUserId=${widget.currentUserId}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Who wore it best?',
          style: AppTextStyles.heading
              .copyWith(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: _secondsNotifier,
            builder: (context, seconds, _) {
              if (seconds <= 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${seconds}s',
                    style: TextStyle(
                      color: seconds <= 10
                          ? Colors.red[200]
                          : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: AppPageBackground(
        child: Stack(
          children: [
            const Positioned.fill(
              child: AmbientSparkles(count: 18, color: Colors.white),
            ),
            SafeArea(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('lobbies')
                    .doc(widget.roomId)
                    .collection('submitted_outfits')
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
                      child: Text('Loading...',
                          style: AppTextStyles.body),
                    );
                  }

                  final allOpponents = snapshot.data!.docs
                      .where((doc) => doc.id != widget.currentUserId)
                      .toList();

                  // Prefer real human players; show bots only when no human has submitted yet.
                  final realOpponents = allOpponents.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return d['isBot'] != true;
                  }).toList();

                  final opponentsOutfits =
                      realOpponents.isNotEmpty ? realOpponents : allOpponents;

                  if (opponentsOutfits.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Waiting for other players...',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subheading,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _hasVoted
                              ? 'Thanks for voting! Results incoming...'
                              : 'Tap a look to vote',
                          style: AppTextStyles.subheading
                              .copyWith(color: AppColors.textDark),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: opponentsOutfits.length,
                          itemBuilder: (context, index) {
                            final submittedData =
                                opponentsOutfits[index].data()
                                    as Map<String, dynamic>;
                            final opponentId =
                                opponentsOutfits[index].id;
                            final isBot =
                                submittedData['isBot'] as bool? ??
                                    false;
                            final outfitData =
                                (submittedData['outfitData']
                                        as Map<String, dynamic>?) ??
                                    {};
                            final username =
                                submittedData['username']
                                        as String? ??
                                    (isBot ? 'Bot' : 'Player');

                            return RevealIn(
                              delay: Duration(
                                  milliseconds: 90 * index),
                              child: _VoteCard(
                                username: username,
                                isBot: isBot,
                                outfitData: outfitData,
                                hasVoted: _hasVoted,
                                isLoading: _isVoting,
                                onVote: () =>
                                    _voteForOutfit(opponentId),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Vote card — live character render or bot PNG
// ─────────────────────────────────────────────────────────

class _VoteCard extends StatelessWidget {
  final String username;
  final bool isBot;
  final Map<String, dynamic> outfitData;
  final bool hasVoted;
  final bool isLoading;
  final VoidCallback onVote;

  const _VoteCard({
    required this.username,
    required this.isBot,
    required this.outfitData,
    required this.hasVoted,
    required this.isLoading,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      scale: 0.95,
      onTap: (hasVoted || isLoading) ? null : onVote,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryLight.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _OutfitView(
                    isBot: isBot, outfitData: outfitData),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 12),
              color: AppColors.cardBgPastel,
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textDark),
                  ),
                  if (!hasVoted) ...[
                    const SizedBox(height: 4),
                    Text(
                      isLoading ? '...' : 'Vote',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Outfit view — reconstructs CharacterPreview from Firestore
//  outfit data; falls back to bot PNG for bot entries.
// ─────────────────────────────────────────────────────────

class _OutfitView extends StatelessWidget {
  final bool isBot;
  final Map<String, dynamic> outfitData;

  const _OutfitView({required this.isBot, required this.outfitData});

  @override
  Widget build(BuildContext context) {
    if (isBot) {
      // bots store imageUrl (set by completePlayIfReady); legacy key was botImage
      final botImage =
          outfitData['imageUrl'] as String? ??
          outfitData['botImage'] as String? ??
          'assets/bots/avatar4.png';
      if (botImage.startsWith('http')) {
        return Image.network(
          botImage,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const _OutfitFallback(),
        );
      }
      return Image.asset(
        botImage,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _OutfitFallback(),
      );
    }

    final character = _characterFromOutfitData(outfitData);
    if (character == null) return const _OutfitFallback();

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
      final gender = data['gender'] == 'boy'
          ? CharacterGender.boy
          : CharacterGender.girl;
      final skinTone = data['skinTone'] as String? ?? 'light';
      final hairAsset = data['hairAsset'] as String? ?? 'hair1';
      final rawIds =
          (data['outfitIds'] as Map<String, dynamic>?) ?? {};

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

class _OutfitFallback extends StatelessWidget {
  const _OutfitFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.checkroom,
              size: 40, color: AppColors.primaryLight),
          const SizedBox(height: 5),
          Text('Loading...',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
