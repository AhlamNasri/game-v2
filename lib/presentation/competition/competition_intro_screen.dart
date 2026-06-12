import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_room_girls/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompetitionIntroScreen extends StatefulWidget {
  final String roomId;

  const CompetitionIntroScreen({super.key, required this.roomId});

  @override
  State<CompetitionIntroScreen> createState() =>
      _CompetitionIntroScreenState();
}

class _CompetitionIntroScreenState extends State<CompetitionIntroScreen> {
  int _secondsLeft = 5;
  Timer? _timer;
  String _theme = '';
  List<dynamic> _players = [];

  @override
  void initState() {
    super.initState();
    _loadLobbyAndStart();
  }

  Future<void> _loadLobbyAndStart() async {
    final doc = await FirebaseFirestore.instance
        .collection('lobbies')
        .doc(widget.roomId)
        .get();

    if (!doc.exists || !mounted) return;

    final data = doc.data()!;
    setState(() {
      _theme = data['theme'] as String? ?? 'Style Libre';
      _players = List<dynamic>.from(data['players'] ?? []);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
        if (mounted) context.go('/play-zone?roomId=${widget.roomId}');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A0D3A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                "Contest Starts",
                textAlign: TextAlign.center,
                style: AppTextStyles.heading.copyWith(
                  color: Colors.amber,
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),

              // Theme
              Text(
                "Theme:",
                style: AppTextStyles.subheading.copyWith(
                    color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                _theme.isEmpty ? '...' : _theme,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading.copyWith(
                  color: Colors.pinkAccent,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 32),

              // Player avatar circles
              if (_players.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    if (i < _players.length) {
                      final player =
                          _players[i] as Map<String, dynamic>;
                      final avatarId =
                          player['avatarId'] as String? ?? 'avatar1';
                      final nickname =
                          player['nickname'] as String? ?? '';
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.3),
                              backgroundImage:
                                  AssetImage('assets/avatars/$avatarId.png'),
                              onBackgroundImageError: (err, _) {},
                            ),
                            const SizedBox(height: 6),
                            Text(
                              nickname,
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white12,
                            child: const Icon(Icons.add,
                                color: Colors.white38),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "...",
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white38),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 40),

              // Countdown
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Text(
                  "$_secondsLeft",
                  key: ValueKey(_secondsLeft),
                  style: AppTextStyles.heading.copyWith(
                    color: Colors.white,
                    fontSize: 80,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Get ready",
                style: AppTextStyles.caption
                    .copyWith(color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
