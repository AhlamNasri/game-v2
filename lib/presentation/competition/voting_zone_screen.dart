import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/character_customization.dart';
import '../../data/models/clothing_item.dart';
import '../../data/repositories/fashion_catalog.dart';
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
  bool _hasVoted = false;

  Future<void> _voteForOutfit(String opponentId) async {
    if (_hasVoted) return;

    setState(() => _hasVoted = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final submittedOutfitsRef = firestore
          .collection('lobbies')
          .doc(widget.roomId)
          .collection('submitted_outfits');

      await submittedOutfitsRef.doc(opponentId).update({
        'votesCount': FieldValue.increment(1),
      });

      // Bots each cast one vote for a random other contestant.
      final outfitsSnapshot = await submittedOutfitsRef.get();
      final allOutfits = outfitsSnapshot.docs;
      final random = Random();

      for (final botDoc in allOutfits) {
        final botData = botDoc.data();
        if (botData['isBot'] == true) {
          final botUid = botDoc.id;
          final validTargets = allOutfits
              .where((doc) => doc.id != botUid)
              .map((doc) => doc.id)
              .toList();
          if (validTargets.isNotEmpty) {
            final chosenTargetId =
                validTargets[random.nextInt(validTargets.length)];
            await submittedOutfitsRef.doc(chosenTargetId).update({
              'votesCount': FieldValue.increment(1),
            });
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote counted!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/result-zone?roomId=${widget.roomId}');
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasVoted = false);
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('Loading...',
                          style: AppTextStyles.body),
                    );
                  }

                  final opponentsOutfits = snapshot.data!.docs
                      .where((doc) => doc.id != widget.currentUserId)
                      .toList();

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
                              ? 'Thanks for voting!'
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
                            final submittedData = opponentsOutfits[index]
                                .data() as Map<String, dynamic>;
                            final opponentId = opponentsOutfits[index].id;
                            final isBot =
                                submittedData['isBot'] as bool? ?? false;
                            final outfitData =
                                submittedData['outfitData']
                                    as Map<String, dynamic>? ??
                                    {};
                            final username =
                                submittedData['username'] as String? ??
                                    (isBot ? 'Bot' : 'Player');

                            return RevealIn(
                              delay: Duration(milliseconds: 90 * index),
                              child: _VoteCard(
                                username: username,
                                isBot: isBot,
                                outfitData: outfitData,
                                hasVoted: _hasVoted,
                                onVote: () => _voteForOutfit(opponentId),
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
  final VoidCallback onVote;

  const _VoteCard({
    required this.username,
    required this.isBot,
    required this.outfitData,
    required this.hasVoted,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      scale: 0.95,
      onTap: hasVoted ? null : onVote,
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
                child: _OutfitView(isBot: isBot, outfitData: outfitData),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: AppColors.cardBgPastel,
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.textDark),
                  ),
                  if (!hasVoted) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Vote',
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
      final botImage = outfitData['botImage'] as String? ??
          'assets/bots/avatar4.png';
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
          const Icon(Icons.checkroom, size: 40, color: AppColors.primaryLight),
          const SizedBox(height: 5),
          Text('Loading...',
              textAlign: TextAlign.center, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
