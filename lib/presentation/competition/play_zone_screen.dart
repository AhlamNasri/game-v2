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
import '../../theme/app_effects.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_widgets.dart';
import '../dressing/widgets/dressup_widgets.dart';
import '../dressing/widgets/wardrobe_panel.dart';
import '../widgets/character_preview.dart';

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
  // Meta
  String _theme = '';
  String _username = '';
  bool _isLoadingMeta = true;

  // Timer
  int _secondsLeft = 180;
  Timer? _timer;
  bool _isSubmitting = false;
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
    _loadMeta();
    _loadOwnedItems();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── data loading ───────────────────────────────────────

  Future<void> _loadMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString('user_nickname') ?? '';

      final doc = await FirebaseFirestore.instance
          .collection('lobbies')
          .doc(widget.roomId)
          .get();

      if (mounted) {
        setState(() {
          _theme = doc.data()?['theme'] as String? ?? '';
          _isLoadingMeta = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMeta = false);
    }
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

  // ── timer ──────────────────────────────────────────────

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 30 && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        t.cancel();
        _submitOutfit(isAuto: true);
      }
    });
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ── submit ─────────────────────────────────────────────

  Future<void> _submitOutfit({required bool isAuto}) async {
    if (_isSubmitting) return;
    _timer?.cancel();
    _pulseController.stop();
    HapticFeedback.mediumImpact();
    setState(() {
      _isSubmitting = true;
      _showSubmitBurst = true;
    });

    try {
      // Build outfit data from live character state
      final character = ref.read(characterProvider);
      final myOutfitData = <String, dynamic>{
        'gender': character.gender.name,
        'skinTone': character.skinTone,
        'hairAsset': character.hairAsset,
        'outfitIds': character.outfit.map(
          (cat, item) => MapEntry(cat.name, item.id),
        ),
      };

      // 3. Write player outfit to Firestore
      final lobbyRef = FirebaseFirestore.instance
          .collection('lobbies')
          .doc(widget.roomId);

      await lobbyRef
          .collection('submitted_outfits')
          .doc(widget.currentUserId)
          .set({
        'userId': widget.currentUserId,
        'username': _username,
        'outfitData': myOutfitData,
        'submittedAt': FieldValue.serverTimestamp(),
        'finishedInTime': !isAuto,
        'isBot': false,
        'votesCount': 0,
      });

      // 4. Write bot outfits
      final lobbySnap = await lobbyRef.get();
      if (lobbySnap.exists) {
        final players =
            List<dynamic>.from(lobbySnap.data()?['players'] ?? []);
        for (final player in players) {
          if (player['isBot'] == true) {
            final botUid = player['uid'] as String;
            final botName =
                player['nickname'] as String? ?? 'Bot';
            final botDoll = player['dollImage'] as String? ??
                'assets/bots/poupee_chic.png';
            await lobbyRef
                .collection('submitted_outfits')
                .doc(botUid)
                .set({
              'userId': botUid,
              'username': botName,
              'outfitData': {'isBotOutfit': true, 'botImage': botDoll},
              'submittedAt': FieldValue.serverTimestamp(),
              'finishedInTime': true,
              'isBot': true,
              'votesCount': 0,
            }, SetOptions(merge: true));
          }
        }
      }

      // 5. Navigate to voting zone
      if (mounted) {
        context.go(
          '/voting-zone?roomId=${widget.roomId}'
          '&currentUserId=${widget.currentUserId}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Submission failed: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ── build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final character = ref.watch(characterProvider);
    final isUrgent = _secondsLeft <= 30;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Countdown — pulses red when ≤30 s
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
                        color: isUrgent ? Colors.red[200] : Colors.white,
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
            // Theme label
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
            // Submit button
            _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : FilledButton.icon(
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
              // ── Left 40 % — doll preview ──────────────
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
                          builder: (context, constraints) =>
                              CharacterPreview(
                            character: character,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          ),
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
              // ── Right 60 % — dressing panel ───────────
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
//  Competition dressing panel (right 60%) — reuses the shared
//  wardrobe so the closet and the contest stay perfectly in sync.
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
        : (categories.isNotEmpty ? categories.first : ClothingCategory.dresses);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 62,
            child: CategoryRail(
              categories: categories,
              selected: active,
              onSelected: onCategorySelected,
              axis: Axis.horizontal,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: WardrobePanel(
              category: active,
              ownedItemIds: ownedItemIds,
              isLoading: isLoadingOwned,
              axis: Axis.horizontal,
            ),
          ),
          const SizedBox(height: 8),
          StickerButton(
            label: 'Random',
            colors: const [AppColors.accent, Color(0xFF8B5CC0)],
            onTap: () =>
                ref.read(characterProvider.notifier).applyBestStyle(),
          ),
        ],
      ),
    );
  }
}
