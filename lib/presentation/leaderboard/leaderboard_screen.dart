import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_effects.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_widgets.dart';

/// Top stylists ranked by XP. Reads the `users` collection ordered by
/// `xp` — requires cross-user read access in Firestore rules. If that
/// rule isn't published yet the query errors with permission-denied,
/// which we surface as a friendly empty state instead of crashing.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard 🏆'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AppPageBackground(
        child: Stack(
          children: [
            const Positioned.fill(
              child: AmbientSparkles(count: 18, color: AppColors.coinGold),
            ),
            SafeArea(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('xp', descending: true)
                    .limit(25)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _LeaderboardMessage(
                      emoji: '🔒',
                      text:
                          'Leaderboard is warming up.\nCheck back soon!',
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const _LeaderboardMessage(
                      emoji: '',
                      text: 'No players ranked yet.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>? ?? {};
                      return RevealIn(
                        delay: Duration(milliseconds: 50 * index),
                        slide: 18,
                        child: _LeaderboardRow(
                          rank: index + 1,
                          nickname: data['nickname'] as String? ?? 'Player',
                          avatarId: data['avatarId'] as String?,
                          level: (data['level'] as int?) ?? 1,
                          xp: (data['xp'] as int?) ?? 0,
                          wins: (data['wins'] as int?) ?? 0,
                          isMe: docs[index].id == myUid,
                        ),
                      );
                    },
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

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String nickname;
  final String? avatarId;
  final int level;
  final int xp;
  final int wins;
  final bool isMe;

  const _LeaderboardRow({
    required this.rank,
    required this.nickname,
    required this.avatarId,
    required this.level,
    required this.xp,
    required this.wins,
    required this.isMe,
  });

  String get _rankLabel {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final podium = rank <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.cardBgPastel : AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColors.primary
              : (podium ? AppColors.coinGold : const Color(0xFFF0E8EF)),
          width: isMe || podium ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Center(
              child: Text(
                _rankLabel,
                style: TextStyle(
                  fontSize: podium ? 22 : 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMid,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            backgroundImage:
                (avatarId != null && avatarId!.isNotEmpty)
                    ? AssetImage('assets/avatars/$avatarId.png')
                    : null,
            onBackgroundImageError:
                (avatarId != null && avatarId!.isNotEmpty) ? (_, _) {} : null,
            child: (avatarId == null || avatarId!.isEmpty)
                ? const Icon(Icons.person,
                    size: 18, color: AppColors.primaryDark)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textDark),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text('Lv.$level  •  🏆 $wins',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$xp',
                  style: AppTextStyles.subheading
                      .copyWith(color: AppColors.primaryDark)),
              Text('XP', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardMessage extends StatelessWidget {
  final String emoji;
  final String text;

  const _LeaderboardMessage({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.subheading
                  .copyWith(color: AppColors.textMid),
            ),
          ],
        ),
      ),
    );
  }
}
