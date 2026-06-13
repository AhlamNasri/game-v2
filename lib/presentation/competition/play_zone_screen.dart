import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/character_provider.dart';
import '../../data/models/clothing_item.dart';
import '../../data/services/lobby_service.dart';
import '../../theme/app_effects.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_widgets.dart';
import '../dressing/widgets/interactive_doll_view.dart';
import '../dressing/widgets/wardrobe_panel.dart';

class PlayZoneScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String currentUserId;

  const PlayZoneScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
  });

  @override
  ConsumerState<PlayZoneScreen> createState() => _PlayZoneScreenState();
}

class _PlayZoneScreenState extends ConsumerState<PlayZoneScreen>
    with SingleTickerProviderStateMixin {
  final LobbyService _lobbyService = LobbyService();

  // Lobby stream
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _lobbySubscription;
  Timer? _ticker;
  DateTime? _playEndsAt;

  // Meta
  String _theme = '';
  String _username = '';
  bool _isLoadingMeta = true;

  // Timer display
  int _secondsLeft = LobbyService.playDuration.inSeconds;
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _timeUpHandled = false;
  bool _navigating = false;
  bool _showSubmitBurst = false;
  late final AnimationController _pulseController;

  // Owned items
  List<String> _ownedItemIds = [];
  bool _isLoadingOwned = true;

  // Panel state
  ClothingCategory _selectedCategory = ClothingCategory.dresses;

  // ── lifecycle ──────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadUsername();
    _loadOwnedItems();
    _bootstrap();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lobbySubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── bootstrap ──────────────────────────────────────────

  Future<void> _bootstrap() async {
    final userId = widget.currentUserId.trim();
    if (widget.roomId.trim().isEmpty || userId.isEmpty) return;

    try {
      await _lobbyService.ensurePlayWindow(
        lobbyId: widget.roomId,
        requestedByUserId: userId,
      );
    } catch (_) {
      // ensurePlayWindow is best-effort; only the host actually writes
    }

    _listenToLobby();
  }

  void _listenToLobby() {
    _lobbySubscription?.cancel();
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
    if (status == 'voting' || status == 'results') {
      _goToVoting();
      return;
    }

    final playEndsAt = data['playEndsAt'];
    final submittedIds = <String>{
      ...?((data['submittedPlayerIds'] as List?)
              ?.map((e) => e.toString()))
    };

    setState(() {
      _theme = data['theme'] as String? ?? '';
      _isLoadingMeta = false;
      _submitted = submittedIds.contains(widget.currentUserId);
      _playEndsAt =
          playEndsAt is Timestamp ? playEndsAt.toDate() : null;
    });

    _syncTicker();
  }

  void _syncTicker() {
    _ticker ??=
        Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    if (!mounted || _navigating) return;

    final endsAt = _playEndsAt;
    if (endsAt == null) return;

    final remaining = endsAt.difference(DateTime.now()).inSeconds;
    final secondsLeft =
        remaining.clamp(0, LobbyService.playDuration.inSeconds);

    if (_secondsLeft != secondsLeft) {
      setState(() => _secondsLeft = secondsLeft);
    }

    if (secondsLeft <= 30 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }

    if (secondsLeft == 0 && !_timeUpHandled) {
      _timeUpHandled = true;
      if (_submitted) {
        unawaited(_lobbyService.completePlayIfReady(
          lobbyId: widget.roomId,
          requestedByUserId: widget.currentUserId,
          force: true,
        ));
      } else {
        _submitOutfit(isAuto: true);
      }
    }
  }

  void _goToVoting() {
    if (_navigating) return;
    _navigating = true;
    _ticker?.cancel();
    _lobbySubscription?.cancel();
    if (mounted) {
      context.go(
        '/voting-zone'
        '?roomId=${widget.roomId}'
        '&currentUserId=${widget.currentUserId}',
      );
    }
  }

  // ── data loading ───────────────────────────────────────

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('user_nickname') ?? '';
  }

  Future<void> _loadOwnedItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoadingOwned = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted) {
      setState(() {
        _ownedItemIds =
            List<String>.from(doc.data()?['boughtItems'] ?? []);
        _isLoadingOwned = false;
      });
    }
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ── submit ─────────────────────────────────────────────

  Future<void> _submitOutfit({required bool isAuto}) async {
    if (_isSubmitting || _submitted) return;
    _ticker?.cancel();
    _pulseController.stop();
    HapticFeedback.mediumImpact();
    setState(() {
      _isSubmitting = true;
      _showSubmitBurst = true;
    });

    try {
      final character = ref.read(characterProvider);
      final myOutfitData = <String, dynamic>{
        'gender': character.gender.name,
        'skinTone': character.skinTone,
        'hairAsset': character.hairAsset,
        'outfitIds': character.outfit.map(
          (cat, item) => MapEntry(cat.name, item.id),
        ),
      };

      await _lobbyService.submitHumanOutfit(
        lobbyId: widget.roomId,
        userId: widget.currentUserId,
        username: _username,
        outfitData: myOutfitData,
        finishedInTime: !isAuto && _secondsLeft > 0,
      );

      await _lobbyService.completePlayIfReady(
        lobbyId: widget.roomId,
        requestedByUserId: widget.currentUserId,
        force: isAuto || _secondsLeft <= 0,
      );

      if (mounted) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Look submitted! Waiting for others...'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ── build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isUrgent = _secondsLeft <= 30;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = isUrgent
                    ? 1.0 + _pulseController.value * 0.12
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        color: isUrgent
                            ? Colors.red[200]
                            : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatTime(_secondsLeft),
                        style: TextStyle(
                          color: isUrgent
                              ? Colors.red[200]
                              : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _isLoadingMeta
                    ? ''
                    : (_theme.isEmpty ? 'Fashion Contest' : _theme),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_submitted)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white70,
                        size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Waiting...',
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              )
            else if (_isSubmitting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            else
              FilledButton.icon(
                onPressed: () => _submitOutfit(isAuto: false),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18),
                label: const Text(
                  '✓ Submit',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.38,
                child: PulseGlow(
                  enabled: isUrgent,
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(6),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Fit the doll within both width and height,
                            // keeping the 1:1.32 aspect ratio.
                            final dollW = (constraints.maxHeight / 1.32)
                                .clamp(0.0, constraints.maxWidth);
                            return Center(
                              child: InteractiveDollView(
                                width: dollW,
                                selectedCategory: _selectedCategory,
                                onCategorySelected: (cat) =>
                                    setState(() => _selectedCategory = cat),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_showSubmitBurst)
                        const SparkleBurst(
                          particles: 18,
                          radius: 120,
                          color: AppColors.primaryLight,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompetitionDressingPanel(
                  selectedCategory: _selectedCategory,
                  ownedItemIds: _ownedItemIds.toSet(),
                  isLoadingOwned: _isLoadingOwned,
                  onCategorySelected: (cat) =>
                      setState(() => _selectedCategory = cat),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Competition dressing panel (right 60%)
// ─────────────────────────────────────────────────────────

class _CompetitionDressingPanel extends ConsumerWidget {
  final ClothingCategory selectedCategory;
  final Set<String> ownedItemIds;
  final bool isLoadingOwned;
  final ValueChanged<ClothingCategory> onCategorySelected;

  const _CompetitionDressingPanel({
    required this.selectedCategory,
    required this.ownedItemIds,
    required this.isLoadingOwned,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(characterProvider);
    final categories = railCategoriesFor(character.gender.name);
    final active = categories.contains(selectedCategory)
        ? selectedCategory
        : (categories.isNotEmpty
            ? categories.first
            : ClothingCategory.dresses);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 60,
                  child: CategoryRail(
                    categories: categories,
                    selected: active,
                    onSelected: onCategorySelected,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: WardrobePanel(
                    category: active,
                    ownedItemIds: ownedItemIds,
                    isLoading: isLoadingOwned,
                    axis: Axis.horizontal,
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
