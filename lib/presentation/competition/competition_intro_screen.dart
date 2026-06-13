import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompetitionIntroScreen extends StatefulWidget {
  final String roomId;

  const CompetitionIntroScreen({super.key, required this.roomId});

  @override
  State<CompetitionIntroScreen> createState() => _CompetitionIntroScreenState();
}

class _CompetitionIntroScreenState extends State<CompetitionIntroScreen> {
  static const int _introSeconds = 5;

  Timer? _timer;
  int _secondsLeft = _introSeconds;
  String _theme = 'Style Libre';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadThemeAndStartTimer());
  }

  Future<void> _loadThemeAndStartTimer() async {
    if (widget.roomId.trim().isEmpty) {
      _showError('Room not found.');
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lobbies')
          .doc(widget.roomId)
          .get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        _showError('Room not found.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _theme = _readText(data, 'theme', fallback: 'Style Libre');
        _loading = false;
        _error = null;
      });

      _startCountdown();
    } catch (error) {
      _showError('Unable to load competition: $error');
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        _goToPlayZone();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _goToPlayZone() {
    if (!mounted) return;
    final uri = Uri(
      path: '/play-zone',
      queryParameters: {'roomId': widget.roomId},
    );
    context.go(uri.toString());
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  String _readText(
    Map<String, dynamic> data,
    String key, {
    required String fallback,
  }) {
    final value = data[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2B2430),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD36B)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2B2430),
        body: _IntroMessage(
          title: 'Competition Unavailable',
          message: _error!,
          actionLabel: 'Back',
          onPressed: () => context.go('/menu'),
        ),
      );
    }

    final progress = _secondsLeft / _introSeconds;

    return Scaffold(
      backgroundColor: const Color(0xFF2B2430),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: _CountdownPanel(
                  secondsLeft: _secondsLeft,
                  progress: progress,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(flex: 5, child: _ThemePanel(theme: _theme)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownPanel extends StatelessWidget {
  final int secondsLeft;
  final double progress;

  const _CountdownPanel({required this.secondsLeft, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD36B), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Contest Starting',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5F4546),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: const Color(0xFFB96B75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$secondsLeft',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 62,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFEFD8CE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFD36B),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Preparing the stage',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8C6E6D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePanel extends StatelessWidget {
  final String theme;

  const _ThemePanel({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3140),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C596D)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD36B),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'CONTEST THEME',
              style: TextStyle(
                color: Color(0xFF4A3312),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            theme,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Create a look that matches the theme and get ready to vote for other stylists.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFE9D8E8),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroMessage extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _IntroMessage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFB96B75),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5F4546),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8C6E6D),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB96B75),
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
