import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_room_girls/data/services/lobby_service.dart';
import 'package:fashion_room_girls/theme/app_theme.dart';
import 'package:fashion_room_girls/theme/app_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LobbyScreen extends StatefulWidget {
  final String lobbyId;

  const LobbyScreen({super.key, required this.lobbyId});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  static const int _autoFillSeconds = 45;

  final LobbyService _lobbyService = LobbyService();
  final List<Timer> _activeTimers = [];
  Timer? _navigationTimer;
  bool _botsScheduled = false;
  bool _isRedirecting = false;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    // Orientation is locked to landscape globally in main().
  }

  void _scheduleBotsIfHost(Map<String, dynamic> lobbyData) {
    if (_botsScheduled || _isRedirecting) return;
    if ((lobbyData['status'] as String? ?? 'waiting') != 'waiting') return;

    final userId = _currentUserId;
    final hostId = lobbyData['hostId'] as String?;
    if (userId == null || userId != hostId) return;

    _botsScheduled = true;
    final random = math.Random();
    _secondsDelay(
      random.nextInt(6) + 8,
      () => _lobbyService.addSingleBot(widget.lobbyId, requestedByUserId: userId),
    );
    _secondsDelay(
      random.nextInt(8) + 20,
      () => _lobbyService.addSingleBot(widget.lobbyId, requestedByUserId: userId),
    );
    _secondsDelay(
      random.nextInt(7) + 38,
      () => _lobbyService.addSingleBot(widget.lobbyId, requestedByUserId: userId),
    );
  }

  void _secondsDelay(int seconds, Future<void> Function() action) {
    final timer = Timer(Duration(seconds: seconds), () async {
      if (!mounted || _isRedirecting) return;
      await action();
    });
    _activeTimers.add(timer);
  }

  void _cancelLobbyTimers() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    _navigationTimer?.cancel();
    _navigationTimer = null;
  }

  @override
  void dispose() {
    final userId = _currentUserId;
    if (!_isRedirecting && userId != null) {
      unawaited(
        _lobbyService.leaveLobby(lobbyId: widget.lobbyId, userId: userId),
      );
    }
    _cancelLobbyTimers();
    super.dispose();
  }

  void _navigateToCompetition() {
    if (_isRedirecting) return;
    _isRedirecting = true;
    _cancelLobbyTimers();

    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.go('/competition?roomId=${widget.lobbyId}');
    });
  }

  Widget _buildPlayerSlot(List<Map<String, dynamic>> players, int index) {
    final player = index < players.length ? players[index] : null;
    final hasPlayer = player != null;
    final avatarId = player?['avatarId']?.toString() ?? 'avatar_doux';
    final nickname = player?['nickname']?.toString() ?? 'Waiting...';

    return SizedBox(
      width: 104,
      child: Column(
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
              radius: 26,
              backgroundColor: hasPlayer
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.black12,
              child: hasPlayer
                  ? Image.asset(
                      'assets/avatars/$avatarId.png',
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, e, _) => const Icon(
                        Icons.person,
                        size: 28,
                        color: AppColors.accent,
                      ),
                    )
                  : const Icon(Icons.add, color: Colors.white),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            hasPlayer ? nickname : 'Waiting...',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasPlayer ? AppColors.primaryDark : Colors.black38,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _parsePlayers(dynamic rawPlayers) {
    if (rawPlayers is! List) return [];
    final players = <Map<String, dynamic>>[];
    for (final p in rawPlayers) {
      if (p is! Map) continue;
      final player = Map<String, dynamic>.from(p);
      final uid = player['uid']?.toString().trim();
      if (uid == null || uid.isEmpty) continue;
      players.add(player);
    }
    return players;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lobbyId.trim().isEmpty) {
      return const Scaffold(body: Center(child: Text('Room not found')));
    }

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
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('lobbies')
              .doc(widget.lobbyId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final lobbyData = snapshot.data?.data();
            if (lobbyData == null) {
              return const Center(child: Text('Room not found'));
            }

            final players = _parsePlayers(lobbyData['players']);
            final count = players.length.clamp(0, LobbyService.maxPlayers);
            final status = lobbyData['status'] as String? ?? 'waiting';
            final theme = lobbyData['theme'] as String? ?? '';
            final isReady =
                status == 'playing' || count >= LobbyService.maxPlayers;

            _scheduleBotsIfHost(lobbyData);

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
                  height: MediaQuery.of(context).size.height * 0.82,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: isReady
                            ? Text(
                                'READY! Starting...',
                                style: AppTextStyles.subheading
                                    .copyWith(color: AppColors.accent),
                              )
                            : CountdownText(
                                initialSeconds: _autoFillSeconds,
                              ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              _buildPlayerSlot(players, 0),
                              const SizedBox(height: 15),
                              _buildPlayerSlot(players, 1),
                            ],
                          ),
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
                                      value: count / LobbyService.maxPlayers,
                                      strokeWidth: 7,
                                      backgroundColor: AppColors.accentLight,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.accent,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$count / ${LobbyService.maxPlayers}',
                                    style: AppTextStyles.heading,
                                  ),
                                ],
                              ),
                              if (theme.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Chip(
                                  label: Text(
                                    theme,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primaryLight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
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
                        'Finding stylists...',
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
  final int initialSeconds;

  const CountdownText({super.key, required this.initialSeconds});

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late int _seconds = widget.initialSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _seconds <= 0) return;
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Starting in: $_seconds s',
      style: AppTextStyles.subheading.copyWith(color: AppColors.accent),
    );
  }
}
