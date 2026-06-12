import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_room_girls/data/services/lobby_service.dart';
import 'package:fashion_room_girls/theme/app_theme.dart';
import 'package:fashion_room_girls/theme/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LobbyScreen extends StatefulWidget {
  final String lobbyId;

  const LobbyScreen({super.key, required this.lobbyId});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final LobbyService _lobbyService = LobbyService();
  final List<Timer> _activeTimers = [];
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    // Orientation is locked to landscape globally in main(); the lobby
    // must not change it (doing so previously flipped the whole
    // competition pipeline to portrait on exit).
    _scheduleProgressiveBots();
  }

  void _scheduleProgressiveBots() {
    final random = Random();
    _secondsDelay(
      random.nextInt(6) + 8,
      () => _lobbyService.addSingleBot(widget.lobbyId),
    );
    _secondsDelay(
      random.nextInt(8) + 20,
      () => _lobbyService.addSingleBot(widget.lobbyId),
    );
    _secondsDelay(
      random.nextInt(7) + 38,
      () => _lobbyService.addSingleBot(widget.lobbyId),
    );
  }

  void _secondsDelay(int seconds, Function action) {
    Timer timer = Timer(Duration(seconds: seconds), () async {
      if (mounted && !_isRedirecting) await action();
    });
    _activeTimers.add(timer);
  }

  @override
  void dispose() {
    for (var timer in _activeTimers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _navigateToCompetition() {
    if (_isRedirecting) return;
    _isRedirecting = true;
    for (var timer in _activeTimers) {
      timer.cancel();
    }
    Timer(const Duration(seconds: 3), () {
      if (mounted) context.go('/competition?roomId=${widget.lobbyId}');
    });
  }

  Widget _buildPlayerSlot(List<dynamic> players, int index) {
    bool hasPlayer = index < players.length;
    var player =
        hasPlayer ? players[index] as Map<String, dynamic> : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: hasPlayer
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: hasPlayer
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.black12,
            child: hasPlayer
                ? Image.asset(
                    'assets/avatars/${player!['avatarId']}.png',
                    errorBuilder: (_, err, s) =>
                        const Icon(Icons.person, color: AppColors.accent),
                  )
                : const Icon(Icons.add, color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          hasPlayer ? player!['nickname'] : "Waiting...",
          style: TextStyle(
            color: hasPlayer ? AppColors.primaryDark : Colors.black38,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background_lobby.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lobbies')
              .doc(widget.lobbyId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Room not found"));
            }

            var lobbyData =
                snapshot.data!.data() as Map<String, dynamic>;
            int count = lobbyData['playerCount'] ?? 0;
            String status = lobbyData['status'] ?? 'waiting';
            String theme = lobbyData['theme'] as String? ?? '';
            List<dynamic> players = lobbyData['players'] ?? [];
            bool isReady = (status == 'playing' || count >= 4);

            if (isReady) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _navigateToCompetition(),
              );
            }

            return Center(
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.82,
                  height: MediaQuery.of(context).size.height * 0.86,
                  child: Column(
                    children: [
                      // Timer / status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: isReady
                            ? Text(
                                "READY! Starting…",
                                style: AppTextStyles.subheading
                                    .copyWith(color: AppColors.accent),
                              )
                            : const CountdownText(),
                      ),
                      const Spacer(),
                      // Player slots row
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              _buildPlayerSlot(players, 0),
                              const SizedBox(height: 15),
                              _buildPlayerSlot(players, 1),
                            ],
                          ),
                          // Centre: count circle + theme chip
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: CircularProgressIndicator(
                                      value: count / 4,
                                      strokeWidth: 7,
                                      backgroundColor:
                                          AppColors.accentLight,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.accent,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "$count / 4",
                                    style: AppTextStyles.heading,
                                  ),
                                ],
                              ),
                              if (theme.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Chip(
                                  label: Text(theme,
                                      style: AppTextStyles.caption
                                          .copyWith(
                                              color:
                                                  AppColors.primaryDark)),
                                  backgroundColor: AppColors.primaryLight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                ),
                              ],
                            ],
                          ),
                          Column(
                            children: [
                              _buildPlayerSlot(players, 2),
                              const SizedBox(height: 15),
                              _buildPlayerSlot(players, 3),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        "Finding players...",
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CountdownText extends StatefulWidget {
  const CountdownText({super.key});
  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  int _seconds = 60;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && _seconds > 0) setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "Starting in: $_seconds s",
      style: AppTextStyles.subheading.copyWith(color: AppColors.accent),
    );
  }
}
