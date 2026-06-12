import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_room_girls/application/character_provider.dart';
import 'package:fashion_room_girls/data/models/achievement.dart';
import 'package:fashion_room_girls/data/models/character_customization.dart';
import 'package:fashion_room_girls/data/services/lobby_service.dart';
import 'package:fashion_room_girls/theme/app_effects.dart';
import 'package:fashion_room_girls/theme/app_theme.dart';
import 'package:fashion_room_girls/theme/app_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  bool _isJoiningLobby = false;

  Future<void> _joinCompetition(Map<String, dynamic> userData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (user.isAnonymous) {
      _showSignInSheet();
      return;
    }

    setState(() => _isJoiningLobby = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final nickname = userData['nickname'] as String? ??
          prefs.getString('user_nickname') ??
          'Player';
      final avatarId = userData['avatarId'] as String? ??
          prefs.getString('user_avatarId') ??
          'avatar1';
      final level = userData['level'] as int? ?? 1;

      final roomId = await LobbyService().findOrCreateLobby(
        currentUserId: user.uid,
        currentUserNickname: nickname,
        currentUserAvatarId: avatarId,
        userLevel: level,
      );

      if (mounted) context.push('/lobby?roomId=$roomId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not join: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoiningLobby = false);
    }
  }

  void _showSignInSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Join the Contest', style: AppTextStyles.heading),
            const SizedBox(height: 8),
            Text(
              'Sign in to compete in the fashion shows!',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Log In',
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/login');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Sign Up',
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/register');
                    },
                    colorStart: AppColors.accent,
                    colorEnd: const Color(0xFF8B5CC0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievements(BuildContext context, Set<String> earnedIds) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('🏅 Achievements', style: AppTextStyles.heading),
                  const Spacer(),
                  Text('${earnedIds.length}/${Achievements.all.length}',
                      style: AppTextStyles.subheading),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final a in Achievements.all)
                        _AchievementTile(
                          achievement: a,
                          earned: earnedIds.contains(a.id),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Close',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final character = ref.watch(characterProvider);
    final user = FirebaseAuth.instance.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;

    return Scaffold(
      body: AppPageBackground(
        child: Stack(
          children: [
            const Positioned.fill(
              child: AmbientSparkles(count: 26, color: Colors.white),
            ),
            SafeArea(
              child: user == null
                  ? _buildContent(context, character, isAnonymous, {})
                  : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final data =
                            (snapshot.hasData && snapshot.data!.exists)
                                ? snapshot.data!.data()
                                    as Map<String, dynamic>
                                : <String, dynamic>{};
                        return _buildContent(
                            context, character, isAnonymous, data);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CharacterCustomization character,
    bool isAnonymous,
    Map<String, dynamic> userData,
  ) {
    final nickname = isAnonymous
        ? 'Guest'
        : (userData['nickname'] as String? ?? 'Player');
    final avatarId = userData['avatarId'] as String?;
    final coins = isAnonymous ? 0 : (userData['coins'] as int? ?? 0);
    final level = userData['level'] as int? ?? 1;
    final xp = userData['xp'] as int? ?? 0;
    final stats = PlayerStats.fromUserData(userData);
    final earnedIds =
        Set<String>.from(userData['achievements'] as List? ?? const []);

    return Column(
      children: [
        _TopBar(
          coins: coins,
          level: level,
          xp: xp,
          onSettings: () => context.push('/settings'),
          onLeaderboard: () => context.push('/leaderboard'),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left panel — 28%
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.27,
                  child: _LeftPanel(
                    nickname: nickname,
                    avatarId: avatarId,
                    stats: stats,
                    showStats: !isAnonymous,
                    onEdit: () => context.push('/character'),
                    onAchievements: () =>
                        _showAchievements(context, earnedIds),
                  ),
                ),
                const SizedBox(width: 14),
                // Right panel — fills remaining space
                Expanded(
                  child: _RightGrid(
                    isAnonymous: isAnonymous,
                    isJoiningLobby: _isJoiningLobby,
                    onCloset: () => context.push('/dressing'),
                    onShop: () => context.push('/shop'),
                    onRoom: () => context.push('/room'),
                    onCompete: () => _joinCompetition(userData),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Top bar
// ─────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int coins;
  final int level;
  final int xp;
  final VoidCallback onSettings;
  final VoidCallback onLeaderboard;

  const _TopBar({
    required this.coins,
    required this.level,
    required this.xp,
    required this.onSettings,
    required this.onLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textDark,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.cardBg.withValues(alpha: 0.85),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onLeaderboard,
            icon: const Icon(Icons.leaderboard_rounded),
            color: AppColors.primaryDark,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.cardBg.withValues(alpha: 0.85),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
            ),
          ),
          Expanded(
            child: Center(
              child: Shimmer(
                highlight: AppColors.primaryLight,
                child: Text(
                  'Fashion Room Girls',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CoinBadge(coins),
          const SizedBox(width: 12),
          XpLevelBar(level: level, xp: xp),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Left panel — doll + nickname + edit button
// ─────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  final String nickname;
  final String? avatarId;
  final PlayerStats stats;
  final bool showStats;
  final VoidCallback onEdit;
  final VoidCallback onAchievements;

  const _LeftPanel({
    required this.nickname,
    required this.avatarId,
    required this.stats,
    required this.showStats,
    required this.onEdit,
    required this.onAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar circle
          if (avatarId != null && avatarId!.isNotEmpty)
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/avatars/$avatarId.png'),
              onBackgroundImageError: (err, _) {},
              backgroundColor: AppColors.primaryLight,
            )
          else
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(
                Icons.person,
                color: AppColors.primaryDark,
                size: 20,
              ),
            ),
          const SizedBox(height: 4),
          // Nickname
          Text(
            nickname,
            style: AppTextStyles.subheading,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (showStats) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(emoji: '🏆', value: '${stats.wins}'),
                const SizedBox(width: 8),
                _StatChip(emoji: '🔥', value: '${stats.currentStreak}'),
              ],
            ),
          ],
          const SizedBox(height: 8),
          // Edit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 6),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                shape: const StadiumBorder(),
              ),
              child: const Text('Edit 🎨'),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onAchievements,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 4),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('🏅 Achievements'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Stat chip (wins / streak)
// ─────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;

  const _StatChip({required this.emoji, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBgPastel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(value,
              style: AppTextStyles.body.copyWith(color: AppColors.textDark)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Achievement tile (wall, in dialog)
// ─────────────────────────────────────────────────────────

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool earned;

  const _AchievementTile({required this.achievement, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: earned ? 1 : 0.42,
      child: Container(
        width: 132,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: earned ? AppColors.cardBgPastel : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: earned ? AppColors.primary : const Color(0xFFE9DCE6),
            width: earned ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              earned ? achievement.emoji : '🔒',
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textDark,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Right 2×2 grid
// ─────────────────────────────────────────────────────────

class _RightGrid extends StatelessWidget {
  final bool isAnonymous;
  final bool isJoiningLobby;
  final VoidCallback onCloset;
  final VoidCallback onShop;
  final VoidCallback onRoom;
  final VoidCallback onCompete;

  const _RightGrid({
    required this.isAnonymous,
    required this.isJoiningLobby,
    required this.onCloset,
    required this.onShop,
    required this.onRoom,
    required this.onCompete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _NavCard(
                  icon: '👗',
                  label: 'My Closet',
                  caption: 'Dress your doll',
                  color: const Color(0xFFFFD6E8),
                  onTap: onCloset,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NavCard(
                  icon: '🛍️',
                  label: 'Shop',
                  caption: 'Buy new clothes',
                  color: const Color(0xFFFFE8B5),
                  onTap: onShop,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _NavCard(
                  icon: '🏠',
                  label: 'My Room',
                  caption: 'Decorate your space',
                  color: const Color(0xFFD6F0D6),
                  onTap: onRoom,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompeteCard(
                  isAnonymous: isAnonymous,
                  isLoading: isJoiningLobby,
                  onTap: onCompete,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Nav card (Closet / Shop / Room)
// ─────────────────────────────────────────────────────────

class _NavCard extends StatelessWidget {
  final String icon;
  final String label;
  final String caption;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.caption,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.subheading),
              const SizedBox(height: 2),
              Text(caption, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Compete card — lock overlay for anonymous users
// ─────────────────────────────────────────────────────────

class _CompeteCard extends StatelessWidget {
  final bool isAnonymous;
  final bool isLoading;
  final VoidCallback onTap;

  const _CompeteCard({
    required this.isAnonymous,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapBounce(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE0D0FF),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE0D0FF).withValues(alpha: 0.55),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: AppColors.accent)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🌟', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 6),
                        Text('Compete', style: AppTextStyles.subheading),
                        const SizedBox(height: 2),
                        Text('Fashion contest', style: AppTextStyles.caption),
                      ],
                    ),
            ),
          ),
          // Lock overlay for anonymous / guest users
          if (isAnonymous)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.black.withValues(alpha: 0.38),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to compete',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
