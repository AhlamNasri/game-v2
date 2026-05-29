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
  int _secondsLeft = 5;
  Timer? _timer;
  String _theme = "Chargement...";

  @override
  void initState() {
    super.initState();
    _loadThemeAndStartTimer();
  }

  // 1. On récupère le thème unique de la partie
  Future<void> _loadThemeAndStartTimer() async {
    final doc = await FirebaseFirestore.instance
        .collection('lobbies')
        .doc(widget.roomId)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _theme = doc.data()?['theme'] ?? "Style Libre";
      });

      // 2. On lance le compte à rebours de 5 secondes
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft > 1) {
          setState(() {
            _secondsLeft--;
          });
        } else {
          _timer?.cancel();
          // 3. Les 5 secondes sont passées ! On bascule vers le vrai jeu
          context.go('/play-zone?roomId=${widget.roomId}');
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Très important pour éviter les fuites de mémoire
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF1E1E2C,
      ), // Fond sombre style "Show de mode"
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "LA COMPÉTITION COMMENCE !",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 50),
            const Text(
              "VOTRE THÈME :",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 10),

            // Affichage du thème écrit en gros
            Text(
              _theme,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),

            const SizedBox(height: 60),

            // Le gros chiffre magique qui descend (5, 4, 3, 2, 1...)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Text(
                "$_secondsLeft",
                key: ValueKey(_secondsLeft),
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Préparez vos tissus...",
              style: TextStyle(
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
