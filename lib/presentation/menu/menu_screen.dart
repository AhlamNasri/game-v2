import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_room_girls/data/services/lobby_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────
//  MenuScreen
// ─────────────────────────────────────────────

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _shimmerController;
  StreamSubscription<User?>? _authSubscription;
  final _firestore = FirebaseFirestore.instance;

  User? _currentUser = FirebaseAuth.instance.currentUser;
  _PlayerProfile _profile = _PlayerProfile.guest();
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
      unawaited(_loadProfile(user));
    });
    unawaited(_loadProfile(_currentUser));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _shimmerController?.dispose();
    super.dispose();
  }

  Future<void> _loadProfile(User? user) async {
    if (mounted) setState(() => _loadingProfile = true);
    try {
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _profile = _PlayerProfile.guest();
          _loadingProfile = false;
        });
        return;
      }
      final snapshot = await _firestore
          .collection('user_rooms')
          .doc(user.uid)
          .get();
      final data = snapshot.data() ?? const <String, dynamic>{};
      final displayName = _displayNameFor(user);
      if (!mounted) return;
      setState(() {
        _profile = _PlayerProfile(
          username: displayName,
          initials: _initialsFor(displayName),
          level: _readInt(data, ['playerLevel', 'level'], fallback: 1),
          xpPoints: _readInt(data, ['xpPoints', 'xp'], fallback: 0),
          nextLevelXp: _readInt(
            data,
            ['nextLevelXp', 'xpToNextLevel'],
            fallback: _xpGoalForLevel(
              _readInt(data, ['playerLevel', 'level'], fallback: 1),
            ),
          ),
          coins: _readInt(data, ['coins', 'gems'], fallback: 0),
        );
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = _PlayerProfile(
          username: _displayNameFor(user),
          initials: _initialsFor(_displayNameFor(user)),
          level: 1,
          xpPoints: 0,
          nextLevelXp: _xpGoalForLevel(1),
          coins: 0,
        );
        _loadingProfile = false;
      });
    }
  }

  static int _readInt(
    Map<String, dynamic> data,
    List<String> keys, {
    required int fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toInt();
    }
    return fallback;
  }

  static int _xpGoalForLevel(int level) => 120 + (level.clamp(1, 99) * 80);

  String _displayNameFor(User? user) {
    if (user == null) return 'Guest Player';
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return user.isAnonymous ? 'Guest Player' : 'Fashion Player';
  }

  String _initialsFor(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .toList();
    if (words.isEmpty) return 'FP';
    return words.map((w) => w.characters.first.toUpperCase()).join();
  }

  Future<void> _startCompetitionMode() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      final String myUid = currentUser?.uid ?? '';
      const int myLevel = 1;
      final String roomId = await LobbyService().findOrCreateLobby(
        currentUserId: myUid,
        currentUserNickname: _profile.username,
        currentUserAvatarId: 'avatar_1',
        userLevel: myLevel,
      );
      if (!mounted) return;
      Navigator.pop(context);
      if (currentUser != null && currentUser.isAnonymous) {
        context.push('/login?roomId=$roomId');
      } else {
        context.push('/lobby?roomId=$roomId');
      }
    } catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de trouver une salle : $error')),
      );
    }
  }

  Future<void> _handleAuthAction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      await FirebaseAuth.instance.signOut();
      if (mounted) context.go('/login');
      return;
    }
    if (mounted) context.push('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _currentUser != null && !(_currentUser!.isAnonymous);

    return Scaffold(
      backgroundColor: _MenuTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('room_assets/room_bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0E0718).withValues(alpha: 0.82),
                  const Color(0xFF1A0B2E).withValues(alpha: 0.76),
                  const Color(0xFF2D0A3C).withValues(alpha: 0.70),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          if (_shimmerController != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmerController!,
                builder: (_, __) => CustomPaint(
                  painter: _AmbientGlowPainter(_shimmerController!.value),
                ),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _MenuLayout(
                  profile: _profile,
                  loading: _loadingProfile,
                  isLoggedIn: isLoggedIn,
                  constraints: constraints,
                  onDecorateRoom: () => context.push('/room'),
                  onCompetitionMode: _startCompetitionMode,
                  onCloset: () => context.push('/dress-up'),
                  onAuthAction: _handleAuthAction,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Layout
// ─────────────────────────────────────────────

class _MenuLayout extends StatelessWidget {
  final _PlayerProfile profile;
  final bool loading;
  final bool isLoggedIn;
  final BoxConstraints constraints;
  final VoidCallback onDecorateRoom;
  final VoidCallback onCompetitionMode;
  final VoidCallback onCloset;
  final VoidCallback onAuthAction;

  const _MenuLayout({
    required this.profile,
    required this.loading,
    required this.isLoggedIn,
    required this.constraints,
    required this.onDecorateRoom,
    required this.onCompetitionMode,
    required this.onCloset,
    required this.onAuthAction,
  });

  @override
  Widget build(BuildContext context) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final hPad = (w * 0.025).clamp(12.0, 32.0);
    final vPad = (h * 0.030).clamp(8.0, 18.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left column ──
          SizedBox(
            width: (w * 0.28).clamp(180.0, 280.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandHeader(h: h),
                SizedBox(height: (h * 0.025).clamp(8.0, 16.0)),
                _ProfileStrip(profile: profile, loading: loading, h: h),
                const Spacer(),
                _BottomBar(
                  isLoggedIn: isLoggedIn,
                  profile: profile,
                  onAuthAction: onAuthAction,
                  h: h,
                ),
              ],
            ),
          ),
          SizedBox(width: (w * 0.03).clamp(12.0, 28.0)),
          // ── Right column: nav buttons ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavButton(
                  label: 'Decorate Room',
                  icon: Icons.chair_alt_outlined,
                  accent: const Color(0xFFD16BA5),
                  h: h,
                  onPressed: onDecorateRoom,
                ),
                SizedBox(height: (h * 0.022).clamp(6.0, 14.0)),
                _NavButton(
                  label: 'Competition Mode',
                  icon: Icons.emoji_events_outlined,
                  accent: const Color(0xFFE0A221),
                  h: h,
                  onPressed: onCompetitionMode,
                  badge: 'LIVE',
                ),
                SizedBox(height: (h * 0.022).clamp(6.0, 14.0)),
                _NavButton(
                  label: 'My Closet',
                  icon: Icons.checkroom_outlined,
                  accent: const Color(0xFF7B8BFF),
                  h: h,
                  onPressed: onCloset,
                ),
                SizedBox(height: (h * 0.022).clamp(6.0, 14.0)),
                _NavButton(
                  label: 'Go Shopping',
                  icon: Icons.shopping_bag_outlined,
                  accent: const Color(0xFF7B8BFF),
                  h: h,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Boutique à venir !')),
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

// ─────────────────────────────────────────────
//  Brand header
// ─────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  final double h;
  const _BrandHeader({required this.h});

  @override
  Widget build(BuildContext context) {
    final titleSize = (h * 0.055).clamp(14.0, 22.0);
    final tagSize = (h * 0.030).clamp(9.0, 12.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'FASHION ROOM',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Container(
              width: 18,
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD16BA5), Color(0xFFE0A221)],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'GIRLS',
              style: TextStyle(
                color: const Color(0xFFD16BA5),
                fontSize: tagSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Profile strip
// ─────────────────────────────────────────────

class _ProfileStrip extends StatelessWidget {
  final _PlayerProfile profile;
  final bool loading;
  final double h;

  const _ProfileStrip({
    required this.profile,
    required this.loading,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    final targetXp = profile.nextLevelXp <= 0 ? 1 : profile.nextLevelXp;
    final progress = (profile.xpPoints.clamp(0, targetXp) / targetXp)
        .toDouble();
    final avatarSize = (h * 0.09).clamp(32.0, 52.0);
    final nameSize = (h * 0.040).clamp(11.0, 16.0);
    final subSize = (h * 0.028).clamp(8.5, 11.0);

    return Container(
      padding: EdgeInsets.all((h * 0.022).clamp(8.0, 14.0)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD16BA5), Color(0xFF8A5BE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  profile.initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: avatarSize * 0.36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: nameSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _PillTag(
                          label: 'LVL ${profile.level}',
                          color: const Color(0xFFD16BA5),
                          fontSize: subSize,
                        ),
                        const SizedBox(width: 5),
                        _PillTag(
                          label: '${profile.coins} ¢',
                          color: const Color(0xFFE0A221),
                          fontSize: subSize,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: subSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${profile.xpPoints.clamp(0, profile.nextLevelXp)} / ${profile.nextLevelXp}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: subSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _ThinProgressBar(
            progress: loading ? 0.0 : progress,
            trackColor: Colors.white.withValues(alpha: 0.10),
            fillColors: const [Color(0xFFD16BA5), Color(0xFF8A5BE8)],
            height: 4,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Bottom bar
// ─────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool isLoggedIn;
  final _PlayerProfile profile;
  final VoidCallback onAuthAction;
  final double h;

  const _BottomBar({
    required this.isLoggedIn,
    required this.profile,
    required this.onAuthAction,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = (h * 0.030).clamp(9.0, 12.0);

    return Row(
      children: [
        Expanded(
          child: _GhostButton(
            icon: isLoggedIn ? Icons.logout : Icons.login,
            label: isLoggedIn ? 'Logout' : 'Login',
            fontSize: fontSize,
            onPressed: onAuthAction,
          ),
        ),
        const SizedBox(width: 8),
        _GhostButton(
          icon: Icons.settings_outlined,
          label: 'Settings',
          fontSize: fontSize,
          onPressed: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Settings coming soon'))),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Nav button  ← compact, content-fitted, centred
// ─────────────────────────────────────────────

class _NavButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final double h;
  final VoidCallback onPressed;
  final String? badge;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.h,
    required this.onPressed,
    this.badge,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final labelSize = (widget.h * 0.048).clamp(13.0, 19.0);
    final badgeSize = (widget.h * 0.028).clamp(8.0, 11.0);
    final iconSize = (widget.h * 0.060).clamp(18.0, 26.0);
    // Vertical padding scales with screen height so the card hugs its content.
    final vPad = (widget.h * 0.030).clamp(12.0, 20.0);

    final bg = _hovered
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.white.withValues(alpha: 0.04);

    final borderColor = _hovered
        ? widget.accent.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.10);

    return AnimatedScale(
      scale: _pressed ? 0.988 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onPressed,
            onHover: (v) => setState(() {
              _hovered = v;
              if (!v) _pressed = false;
            }),
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            splashColor: widget.accent.withValues(alpha: 0.12),
            highlightColor: widget.accent.withValues(alpha: 0.06),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accent bar — stretches to intrinsic height automatically
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _hovered ? 4 : 3,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                  ),
                  // Content — centred both axes, padded to fit text
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: vPad,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            widget.icon,
                            color: widget.accent,
                            size: iconSize,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: labelSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (widget.badge != null) ...[
                            const SizedBox(width: 10),
                            _BadgePill(
                              label: widget.badge!,
                              color: widget.accent,
                              fontSize: badgeSize,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Chevron — vertically centred
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _hovered ? 1.0 : 0.28,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          Icons.chevron_right,
                          color: widget.accent,
                          size: iconSize * 0.9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Small reusable widgets
// ─────────────────────────────────────────────

class _PillTag extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const _PillTag({
    required this.label,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const _BadgePill({
    required this.label,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double fontSize;
  final VoidCallback onPressed;

  const _GhostButton({
    required this.icon,
    required this.label,
    required this.fontSize,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        splashColor: Colors.white.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.55), size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThinProgressBar extends StatelessWidget {
  final double progress;
  final Color trackColor;
  final List<Color> fillColors;
  final double height;

  const _ThinProgressBar({
    required this.progress,
    required this.trackColor,
    required this.fillColors,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          children: [
            Container(height: height, color: trackColor),
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: fillColors),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Ambient glow painter
// ─────────────────────────────────────────────

class _AmbientGlowPainter extends CustomPainter {
  final double t;
  _AmbientGlowPainter(this.t);

  static const _glows = [
    _GlowDef(0.15, 0.20, 0.00, Color(0xFFD16BA5), 0.07),
    _GlowDef(0.85, 0.75, 0.33, Color(0xFF8A5BE8), 0.06),
    _GlowDef(0.50, 0.88, 0.66, Color(0xFFE0A221), 0.05),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final g in _glows) {
      final phase = ((t + g.delay) % 1.0) * math.pi * 2;
      final opacity = g.opacity * (0.6 + (math.sin(phase) + 1) * 0.2);
      final radius = size.shortestSide * 0.38;
      final center = Offset(g.x * size.width, g.y * size.height);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              g.color.withValues(alpha: opacity),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..blendMode = BlendMode.screen,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter old) => old.t != t;
}

class _GlowDef {
  final double x, y, delay, opacity;
  final Color color;
  const _GlowDef(this.x, this.y, this.delay, this.color, this.opacity);
}

// ─────────────────────────────────────────────
//  Theme constants
// ─────────────────────────────────────────────

abstract class _MenuTheme {
  static const bg = Color(0xFF0E0718);
}

// ─────────────────────────────────────────────
//  Player profile model
// ─────────────────────────────────────────────

class _PlayerProfile {
  final String username;
  final String initials;
  final int level;
  final int xpPoints;
  final int nextLevelXp;
  final int coins;

  const _PlayerProfile({
    required this.username,
    required this.initials,
    required this.level,
    required this.xpPoints,
    required this.nextLevelXp,
    required this.coins,
  });

  factory _PlayerProfile.guest() => _PlayerProfile(
    username: 'Guest Player',
    initials: 'GP',
    level: 1,
    xpPoints: 0,
    nextLevelXp: _MenuScreenState._xpGoalForLevel(1),
    coins: 0,
  );
}
