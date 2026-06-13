import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultZoneScreen extends StatefulWidget {
  final String roomId;
  final String currentUserId;

  const ResultZoneScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
  });

  @override
  State<ResultZoneScreen> createState() => _ResultZoneScreenState();
}

class _ResultZoneScreenState extends State<ResultZoneScreen> {
  bool _localProfileSynced = false;

  String get _currentUserId => widget.currentUserId.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F1),
      appBar: AppBar(
        title: const Text(
          'Resultats du defile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFB96B75),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        toolbarHeight: 45,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('lobbies')
            .doc(widget.roomId)
            .snapshots(),
        builder: (context, lobbySnapshot) {
          if (lobbySnapshot.connectionState == ConnectionState.waiting &&
              !lobbySnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDCA1A7)),
              ),
            );
          }

          final playerNames = _playerNamesFrom(lobbySnapshot.data?.data());

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('lobbies')
                .doc(widget.roomId)
                .collection('submitted_outfits')
                .snapshots(),
            builder: (context, outfitsSnapshot) {
              if (outfitsSnapshot.connectionState == ConnectionState.waiting &&
                  !outfitsSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFDCA1A7),
                    ),
                  ),
                );
              }

              final results =
                  (outfitsSnapshot.data?.docs ?? [])
                      .map((doc) => _resultFromDoc(doc, playerNames))
                      .toList()
                    ..sort((a, b) {
                      final voteCompare = b.votes.compareTo(a.votes);
                      if (voteCompare != 0) return voteCompare;
                      return a.username.compareTo(b.username);
                    });

              if (results.isEmpty) {
                return const Center(
                  child: Text(
                    'Calcul des scores finaux...',
                    style: TextStyle(
                      color: Color(0xFF704E52),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              final winner = results.first;
              final currentUserResult = _currentUserResult(results);
              _syncLocalProfileAfterReward(results);

              return SafeArea(
                child: _ResultsContent(
                  winner: winner,
                  currentUserResult: currentUserResult,
                  results: results,
                  onHome: () => context.go('/menu'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  _OutfitResult _resultFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> playerNames,
  ) {
    final data = doc.data();
    final outfitData = data['outfitData'] is Map
        ? Map<String, dynamic>.from(data['outfitData'] as Map)
        : <String, dynamic>{};
    final rewardData = data['reward'] is Map
        ? Map<String, dynamic>.from(data['reward'] as Map)
        : <String, dynamic>{};
    final isBot = data['isBot'] == true;
    final username = data['username']?.toString().trim();
    final playerName = playerNames[doc.id];

    return _OutfitResult(
      userId: doc.id,
      username: _displayNameForOutfit(
        submittedName: username,
        playerName: playerName,
        isBot: isBot,
      ),
      isBot: isBot,
      votes: _readInt(data, 'votesCount'),
      imageUrl: outfitData['imageUrl']?.toString(),
      xp: _readIntOrNull(rewardData, 'xp'),
      coins: _readIntOrNull(rewardData, 'coins'),
      rank: _readIntOrNull(rewardData, 'rank'),
      oldLevel: _readIntOrNull(rewardData, 'oldLevel'),
      newLevel: _readIntOrNull(rewardData, 'newLevel'),
      oldXp: _readIntOrNull(rewardData, 'oldXp'),
      newXp: _readIntOrNull(rewardData, 'newXp'),
      oldCoins: _readIntOrNull(rewardData, 'oldCoins'),
      newCoins: _readIntOrNull(rewardData, 'newCoins'),
      nextLevelXp: _readIntOrNull(rewardData, 'nextLevelXp'),
    );
  }

  _OutfitResult? _currentUserResult(List<_OutfitResult> results) {
    if (_currentUserId.isEmpty) return null;
    for (final result in results) {
      if (result.userId == _currentUserId) return result;
    }
    return null;
  }

  Map<String, String> _playerNamesFrom(Map<String, dynamic>? lobbyData) {
    final rawPlayers = lobbyData?['players'];
    if (rawPlayers is! List) return const <String, String>{};

    final names = <String, String>{};
    for (final rawPlayer in rawPlayers) {
      if (rawPlayer is! Map) continue;

      final uid = rawPlayer['uid']?.toString().trim();
      if (uid == null || uid.isEmpty) continue;

      final nickname = rawPlayer['nickname']?.toString().trim();
      final name = rawPlayer['name']?.toString().trim();
      final displayName =
          nickname != null && nickname.isNotEmpty ? nickname : name;

      if (displayName != null && displayName.isNotEmpty) {
        names[uid] = displayName;
      }
    }

    return names;
  }

  String _displayNameForOutfit({
    required String? submittedName,
    required String? playerName,
    required bool isBot,
  }) {
    final cleanPlayerName = playerName?.trim();
    if (cleanPlayerName != null && cleanPlayerName.isNotEmpty) {
      return cleanPlayerName;
    }

    final cleanSubmittedName = submittedName?.trim();
    if (cleanSubmittedName != null &&
        cleanSubmittedName.isNotEmpty &&
        !_isGenericPlayerName(cleanSubmittedName)) {
      return cleanSubmittedName;
    }

    return isBot ? 'Modele Virtuel' : 'Styliste';
  }

  bool _isGenericPlayerName(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e');
    return normalized == 'joueur' ||
        normalized == 'styliste reel' ||
        normalized == 'modele virtuel';
  }

  void _syncLocalProfileAfterReward(List<_OutfitResult> results) {
    if (_localProfileSynced || _currentUserId.isEmpty) return;

    final hasCurrentUserReward = results.any(
      (result) => result.userId == _currentUserId && result.hasReward,
    );
    if (!hasCurrentUserReward) return;

    _localProfileSynced = true;
    unawaited(_syncLocalProfileFromUsers(_currentUserId));
  }

  Future<void> _syncLocalProfileFromUsers(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final data = snapshot.data();
      if (data == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', userId);

      final xp = _readIntOrNull(data, 'xp');
      final coins = _readIntOrNull(data, 'coins');
      final level = _readIntOrNull(data, 'level');

      if (xp != null) await prefs.setInt('user_xp', xp);
      if (coins != null) await prefs.setInt('user_coins', coins);
      if (level != null) await prefs.setInt('user_level', level);
    } catch (error) {
      debugPrint('Impossible de synchroniser le profil local : $error');
    }
  }

  int _readInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is num ? value.toInt() : 0;
  }

  int? _readIntOrNull(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is num ? value.toInt() : null;
  }
}

class _ResultsContent extends StatelessWidget {
  final _OutfitResult winner;
  final _OutfitResult? currentUserResult;
  final List<_OutfitResult> results;
  final VoidCallback onHome;

  const _ResultsContent({
    required this.winner,
    required this.currentUserResult,
    required this.results,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide =
            constraints.maxWidth >= 720 && constraints.maxHeight >= 520;
        final padding = EdgeInsets.symmetric(
          horizontal: isWide ? 18 : 14,
          vertical: isWide ? 14 : 12,
        );

        if (!isWide) {
          return ListView(
            padding: padding,
            physics: const BouncingScrollPhysics(),
            children: [
              _ResultsHeader(resultsCount: results.length),
              const SizedBox(height: 12),
              SizedBox(height: 250, child: _WinnerPanel(result: winner)),
              const SizedBox(height: 14),
              _RankingSection(results: results, shrinkWrap: true),
              if (currentUserResult?.hasReward == true) ...[
                const SizedBox(height: 12),
                _RewardSummaryCard(result: currentUserResult!),
              ],
              const SizedBox(height: 14),
              _HomeButton(onPressed: onHome),
            ],
          );
        }

        return Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResultsHeader(resultsCount: results.length),
                    const SizedBox(height: 12),
                    Expanded(child: _WinnerPanel(result: winner)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _RankingSection(results: results)),
                    const SizedBox(height: 12),
                    if (currentUserResult?.hasReward == true) ...[
                      _RewardSummaryCard(result: currentUserResult!),
                      const SizedBox(height: 12),
                    ],
                    _HomeButton(onPressed: onHome),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final int resultsCount;

  const _ResultsHeader({required this.resultsCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0DAD0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD36B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFF7A4B12),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Defile termine',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF5F4546),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Score final et recompenses',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF8C6E6D),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CountBadge(count: resultsCount),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4E7B74).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count looks',
        maxLines: 1,
        style: const TextStyle(
          color: Color(0xFF2E5F58),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RankingSection extends StatelessWidget {
  final List<_OutfitResult> results;
  final bool shrinkWrap;

  const _RankingSection({required this.results, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    final list = ListView.builder(
      itemCount: results.length,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return _RankingTile(
          result: results[index],
          rank: _rankForIndex(results, index),
        );
      },
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0DAD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Row(
            children: [
              const Icon(
                Icons.leaderboard_rounded,
                color: Color(0xFFB96B75),
                size: 18,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Classement',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF5F4546),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${results.length} styles',
                style: const TextStyle(
                  color: Color(0xFF8C6E6D),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (shrinkWrap) list else Expanded(child: list),
        ],
      ),
    );
  }

  int _rankForIndex(List<_OutfitResult> results, int index) {
    final votes = results[index].votes;
    return results.where((result) => result.votes > votes).length + 1;
  }
}

class _HomeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HomeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5F4546),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.home_rounded, size: 19),
      label: const Text(
        "Retour a l'accueil",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
      ),
    );
  }
}

class _RewardSummaryCard extends StatelessWidget {
  final _OutfitResult result;

  const _RewardSummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final nextLevelXp = result.nextLevelXp;
    final oldXp = result.oldXp ?? 0;
    final newXp = result.newXp ?? oldXp + (result.xp ?? 0);
    final hasXpBar = nextLevelXp != null && nextLevelXp > 0;
    final oldProgress =
        hasXpBar ? (oldXp / nextLevelXp).clamp(0.0, 1.0) : 0.0;
    final newProgress =
        hasXpBar ? (newXp / nextLevelXp).clamp(0.0, 1.0) : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: result.leveledUp
                ? const Color(0xFFFFD700)
                : const Color(0xFFB96B75).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F4546).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: result.leveledUp
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF4E7B74),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    result.leveledUp
                        ? Icons.workspace_premium_rounded
                        : Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        result.leveledUp
                            ? 'NIVEAU SUPERIEUR !'
                            : 'Tes gains',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF5F4546),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        result.rank == null
                            ? 'Recompense de la partie'
                            : 'Rang #${result.rank} sur le podium',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              const Color(0xFF5F4546).withValues(alpha: 0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (result.newLevel != null)
                  _LevelBadge(
                    oldLevel: result.oldLevel,
                    newLevel: result.newLevel!,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _RewardPill(
                    icon: Icons.bolt_rounded,
                    label: '+${result.xp ?? 0} XP',
                    color: const Color(0xFF5E5AA8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RewardPill(
                    icon: Icons.monetization_on_rounded,
                    label: '+${result.coins ?? 0}',
                    color: const Color(0xFFC17B18),
                  ),
                ),
              ],
            ),
            if (hasXpBar) ...[
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: oldProgress, end: newProgress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEFE6E2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        result.leveledUp
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF5E5AA8),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                '$newXp / $nextLevelXp XP',
                style: TextStyle(
                  color: const Color(0xFF5F4546).withValues(alpha: 0.65),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int? oldLevel;
  final int newLevel;

  const _LevelBadge({required this.oldLevel, required this.newLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF5F4546),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        oldLevel != null && oldLevel != newLevel
            ? 'LVL $oldLevel -> $newLevel'
            : 'LVL $newLevel',
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WinnerPanel extends StatelessWidget {
  final _OutfitResult result;

  const _WinnerPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0DAD0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5F4546).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: 78,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD36B).withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Positioned.fill(
            bottom: 78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 44, 18, 14),
              child: result.imageUrl != null
                  ? Image.asset(
                      result.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackIcon(),
                    )
                  : (result.isBot
                      ? Image.asset(
                          'assets/bots/poupee_chic.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackIcon(),
                        )
                      : _buildFallbackIcon()),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD36B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 15,
                    color: Color(0xFF7A4B12),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'MEILLEUR SCORE',
                    style: TextStyle(
                      color: Color(0xFF7A4B12),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF5F4546),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${result.votes} votes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: const Color(0xFF5F4546),
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Gagnante du defile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFFFD36B),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.username,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  if (result.hasReward) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${result.xp} XP  |  +${result.coins} coins',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFD36B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return const Icon(
      Icons.checkroom_rounded,
      size: 58,
      color: Color(0xFFB96B75),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final _OutfitResult result;
  final int rank;

  const _RankingTile({required this.result, required this.rank});

  @override
  Widget build(BuildContext context) {
    final isWinner = rank == 1;

    Color rankColor = const Color(0xFF5F4546).withValues(alpha: 0.1);
    Color rankTextColor = const Color(0xFF5F4546);

    if (rank == 1) {
      rankColor = const Color(0xFFFFD36B);
      rankTextColor = const Color(0xFF7A4B12);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0).withValues(alpha: 0.25);
      rankTextColor = const Color(0xFF666666);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32).withValues(alpha: 0.2);
      rankTextColor = const Color(0xFF8B4513);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isWinner ? const Color(0xFFFFFBF2) : const Color(0xFFFFFEFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isWinner ? const Color(0xFFFFD36B) : const Color(0xFFEFE6E2),
          width: 1,
        ),
      ),
      child: ListTile(
        dense: true,
        minVerticalPadding: 7,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: rankColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$rank',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: rankTextColor,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          result.username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color:
                isWinner ? const Color(0xFF7A4B12) : const Color(0xFF5F4546),
          ),
        ),
        subtitle: result.hasReward
            ? Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  _MiniStat(
                    icon: Icons.bolt_rounded,
                    label: '+${result.xp} XP',
                    color: const Color(0xFF5E5AA8),
                  ),
                  _MiniStat(
                    icon: Icons.monetization_on_rounded,
                    label: '+${result.coins}',
                    color: const Color(0xFFC17B18),
                  ),
                ],
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4E7B74).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${result.votes} votes',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: Color(0xFF2E5F58),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _OutfitResult {
  final String userId;
  final String username;
  final bool isBot;
  final int votes;
  final String? imageUrl;
  final int? xp;
  final int? coins;
  final int? rank;
  final int? oldLevel;
  final int? newLevel;
  final int? oldXp;
  final int? newXp;
  final int? oldCoins;
  final int? newCoins;
  final int? nextLevelXp;

  const _OutfitResult({
    required this.userId,
    required this.username,
    required this.isBot,
    required this.votes,
    required this.imageUrl,
    required this.xp,
    required this.coins,
    required this.rank,
    required this.oldLevel,
    required this.newLevel,
    required this.oldXp,
    required this.newXp,
    required this.oldCoins,
    required this.newCoins,
    required this.nextLevelXp,
  });

  bool get hasReward => xp != null && coins != null;

  bool get leveledUp =>
      oldLevel != null && newLevel != null && newLevel! > oldLevel!;
}
