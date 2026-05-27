import 'package:flutter/material.dart';

<<<<<<< HEAD
class CompetitionScreen extends StatefulWidget {
  const CompetitionScreen({super.key});

  @override
  State<CompetitionScreen> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<CompetitionScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('welcome de the compition '));
  }
=======
class CompetitionScreen extends StatelessWidget {
  final String roomId;

  const CompetitionScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) => const Scaffold();
>>>>>>> upstream/develop
}
