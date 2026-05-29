// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class LobbyScreen extends StatelessWidget {
//   final String lobbyId;

//   const LobbyScreen({super.key, required this.lobbyId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(
//         0xFFF5E6E8,
//       ), // Une jolie couleur pastel pour ton jeu de mode
//       body: Center(
//         child: StreamBuilder<DocumentSnapshot>(
//           // On écoute en temps réel le lobby spécifique sur Firebase
//           stream: FirebaseFirestore.instance
//               .collection('lobbies')
//               .doc(lobbyId)
//               .snapshots(),
//           builder: (context, snapshot) {
//             // 1. En attendant la connexion à Firebase
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const CircularProgressIndicator();
//             }

//             // 2. Si le lobby n'existe pas ou qu'il y a une erreur
//             if (!snapshot.hasData || !snapshot.data!.exists) {
//               return const Text("Erreur : Impossible de charger la salle.");
//             }

//             // 3. On récupère les données réelles de Firebase
//             var lobbyData = snapshot.data!.data() as Map<String, dynamic>;
//             int count = lobbyData['playerCount'] ?? 0;
//             int level = lobbyData['levelRequired'] ?? 1;
//             String status = lobbyData['status'] ?? 'waiting';

//             // DÉCLENCHEMENT : Si la compétition a commencé, on change d'écran !
//             if (status == 'playing') {
//               // On utilise un petit délai pour ne pas bloquer le build de Flutter
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 context.go(
//                   '/competition?roomId=$lobbyId',
//                 ); // Tu activeras ça pour aller vers ton jeu !
//               });
//             }

//             return Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   "Salon de Stylisme",
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.purple,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   "Niveau requis : $level",
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//                 const SizedBox(height: 40),

//                 // Un joli cercle visuel pour afficher le nombre de joueurs
//                 Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     SizedBox(
//                       width: 150,
//                       height: 150,
//                       child: CircularProgressIndicator(
//                         value:
//                             count / 4, // Remplissage du cercle (ex: 2/4 = 50%)
//                         strokeWidth: 12,
//                         backgroundColor: Colors.grey[300],
//                         valueColor: const AlwaysStoppedAnimation<Color>(
//                           Colors.purple,
//                         ),
//                       ),
//                     ),
//                     Text(
//                       "$count / 4",
//                       style: const TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 40),
//                 const Text(
//                   "Recherche d'autres joueuses...",
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 10),
//                 const SizedBox(
//                   width: 30,
//                   height: 30,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fashion_room_girls/data/services/LobbyService.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class LobbyScreen extends StatefulWidget {
//   final String lobbyId;

//   const LobbyScreen({super.key, required this.lobbyId});

//   @override
//   State<LobbyScreen> createState() => _LobbyScreenState();
// }

// class _LobbyScreenState extends State<LobbyScreen> {
//   final LobbyService _lobbyService = LobbyService();
//   Timer? _botTimer;

//   @override
//   void initState() {
//     super.initState();
//     _startBotCountdown();
//   }

//   /// Démarre le décompte d'une minute avant de compléter la salle avec des IA
//   void _startBotCountdown() {
//     _botTimer = Timer(const Duration(minutes: 1), () async {
//       if (mounted) {
//         await _lobbyService.fillLobbyWithBots(widget.lobbyId);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     // 🛑 Destruction indispensable du timer pour éviter les fuites de mémoire (Memory leaks)
//     _botTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5E6E8),
//       body: Center(
//         child: StreamBuilder<DocumentSnapshot>(
//           stream: FirebaseFirestore.instance
//               .collection('lobbies')
//               .doc(widget.lobbyId)
//               .snapshots(),
//           builder: (context, snapshot) {
//             // 1. Attente de la première réponse Firebase
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const CircularProgressIndicator();
//             }

//             // 2. Si le document a été supprimé ou n'existe pas
//             if (!snapshot.hasData || !snapshot.data!.exists) {
//               return const Text("Erreur : Impossible de charger la salle.");
//             }

//             // 3. Extraction des données
//             var lobbyData = snapshot.data!.data() as Map<String, dynamic>;
//             int count = lobbyData['playerCount'] ?? 0;
//             int level = lobbyData['levelRequired'] ?? 1;
//             String status = lobbyData['status'] ?? 'waiting';

//             // 🎯 CONDITION DE DÉPART : Si la partie commence (Statut changé par les humains ou les robots)
//             if (status == 'playing') {
//               _botTimer?.cancel(); // On stoppe le timer puisqu'on part jouer !
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 context.go('/competition?roomId=${widget.lobbyId}');
//               });
//             }

//             return Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   "Salon de Stylisme",
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.purple,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   "Niveau requis : $level",
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//                 const SizedBox(height: 40),

//                 // Composant visuel du nombre de joueurs
//                 Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     SizedBox(
//                       width: 150,
//                       height: 150,
//                       child: CircularProgressIndicator(
//                         value: count / 4,
//                         strokeWidth: 12,
//                         backgroundColor: Colors.grey[300],
//                         valueColor: const AlwaysStoppedAnimation<Color>(
//                           Colors.purple,
//                         ),
//                       ),
//                     ),
//                     Text(
//                       "$count / 4",
//                       style: const TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 40),
//                 const Text(
//                   "Recherche d'autres joueuses...",
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 10),
//                 const SizedBox(
//                   width: 30,
//                   height: 30,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fashion_room_girls/data/services/LobbyService.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';

// class LobbyScreen extends StatefulWidget {
//   final String lobbyId;

//   const LobbyScreen({super.key, required this.lobbyId});

//   @override
//   State<LobbyScreen> createState() => _LobbyScreenState();
// }

// class _LobbyScreenState extends State<LobbyScreen> {
//   final LobbyService _lobbyService = LobbyService();
//   Timer? _botTimer;
//   bool _isRedirecting = false;

//   @override
//   void initState() {
//     super.initState();

//     // Force l'affichage en mode Paysage
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);

//     _startBotTimer();
//   }

//   /// Démarre l'unique timer de fond pour Firebase (plus de setState ici !)
//   void _startBotTimer() {
//     _botTimer = Timer(const Duration(minutes: 1), () async {
//       if (mounted && !_isRedirecting) {
//         await _lobbyService.fillLobbyWithBots(widget.lobbyId);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     // Remet l'application en mode Portrait normal en quittant
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);

//     _botTimer?.cancel();
//     super.dispose();
//   }

//   void _navigateToCompetition() {
//     if (_isRedirecting) return;
//     _isRedirecting = true;
//     _botTimer?.cancel();

//     Timer(const Duration(seconds: 3), () {
//       if (mounted) {
//         context.go('/competition?roomId=${widget.lobbyId}');
//       }
//     });
//   }

//   Widget _buildPlayerSlot(List<dynamic> players, int index) {
//     if (index < players.length) {
//       var player = players[index] as Map<String, dynamic>;
//       String nickname = player['nickname'] ?? 'Joueur';
//       String avatarId = player['avatarId'] ?? 'avatar_1';

//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.purple.withAlpha(30),
//               child: Padding(
//                 padding: const EdgeInsets.all(4.0),
//                 child: Image.asset(
//                   'assets/avatars/$avatarId.png',
//                   fit: BoxFit.contain,
//                   errorBuilder: (context, error, stackTrace) =>
//                       const Icon(Icons.person, size: 30, color: Colors.purple),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 4),
//             SizedBox(
//               width: 90,
//               child: Text(
//                 nickname,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//       );
//     } else {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.grey[300],
//               child: const Icon(Icons.add, size: 24, color: Colors.white),
//             ),
//             const SizedBox(height: 4),
//             const Text(
//               "En attente...",
//               style: TextStyle(color: Colors.grey, fontSize: 11),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5E6E8),
//       body: StreamBuilder<DocumentSnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('lobbies')
//             .doc(widget.lobbyId)
//             .snapshots(),
//         builder: (context, snapshot) {
//           // 🛑 ICI : On n'affiche le loader qu'au TOUT PREMIER chargement.
//           // S'il y a une mise à jour de données (Data), on garde l'ancien écran stable.
//           if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || !snapshot.data!.exists) {
//             return const Center(child: Text("Erreur : Impossible de charger la salle."));
//           }

//           var lobbyData = snapshot.data!.data() as Map<String, dynamic>;
//           int count = lobbyData['playerCount'] ?? 0;
//           String status = lobbyData['status'] ?? 'waiting';
//           List<dynamic> players = lobbyData['players'] ?? [];

//           final bool isReady = status == 'playing' || count >= 4;

//           if (isReady) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               _navigateToCompetition();
//             });
//           }

//           return SafeArea(
//             child: Stack(
//               children: [
//                 // ⏱️ 1. LE TIMER EN HAUT (Isolé pour ne plus faire sauter l'écran)
//                 Align(
//                   alignment: Alignment.topCenter,
//                   child: Padding(
//                     padding: const EdgeInsets.only(top:12.0),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: Colors.purple.withAlpha(40),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: isReady
//                               ? const Text(
//                                   "Match trouvé ! Préparation...",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.purple,
//                                   ),
//                                 )
//                               : const CountdownText(), // 👈 Utilisation du nouveau widget autonome
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           isReady
//                               ? "Début de la compétition imminent !"
//                               : "Recherche d'autres stylistes...",
//                           style: const TextStyle(fontSize: 13, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // 2. LA DISPOSITION HORIZONTALE (ROW)
//                 Center(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 40.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             _buildPlayerSlot(players, 0),
//                             const SizedBox(height: 10),
//                             _buildPlayerSlot(players, 1),
//                           ],
//                         ),
//                         Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             SizedBox(
//                               width: 110,
//                               height: 110,
//                               child: CircularProgressIndicator(
//                                 value: count / 4,
//                                 strokeWidth: 8,
//                                 backgroundColor: Colors.grey[300],
//                                 valueColor: const AlwaysStoppedAnimation<Color>(
//                                   Colors.purple,
//                                 ),
//                               ),
//                             ),
//                             Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   "$count / 4",
//                                   style: const TextStyle(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 if (!isReady)
//                                   const SizedBox(
//                                     width: 14,
//                                     height: 14,
//                                     child: CircularProgressIndicator(strokeWidth: 1.5),
//                                   )
//                               ],
//                             ),
//                           ],
//                         ),
//                         Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             _buildPlayerSlot(players, 2),
//                             const SizedBox(height: 10),
//                             _buildPlayerSlot(players, 3),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// /// ⏱️ SOUS-WIDGET AUTONOME POUR LE TEXTE DU COMPTE À REBOURS
// /// Il se reconstruit tout seul chaque seconde sans impacter le reste du LobbyScreen !
// class CountdownText extends StatefulWidget {
//   const CountdownText({super.key});

//   @override
//   State<CountdownText> createState() => _CountdownTextState();
// }

// class _CountdownTextState extends State<CountdownText> {
//   int _secondsRemaining = 60;
//   Timer? _ticker;

//   @override
//   void initState() {
//     super.initState();
//     _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) {
//         setState(() {
//           if (_secondsRemaining > 0) {
//             _secondsRemaining--;
//           } else {
//             _ticker?.cancel();
//           }
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _ticker?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       "Lancement dans : $_secondsRemaining s",
//       style: const TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//         color: Colors.purple,
//       ),
//     );
//   }
// }
//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// import 'dart:async';
// import 'dart:math'; // 👈 Nécessaire pour générer des temps d'attente aléatoires
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fashion_room_girls/data/services/LobbyService.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';

// class LobbyScreen extends StatefulWidget {
//   final String lobbyId;

//   const LobbyScreen({super.key, required this.lobbyId});

//   @override
//   State<LobbyScreen> createState() => _LobbyScreenState();
// }

// class _LobbyScreenState extends State<LobbyScreen> {
//   final LobbyService _lobbyService = LobbyService();
//   final List<Timer> _activeTimers =
//       []; // 📋 Liste pour suivre et détruire proprement tous nos timers
//   bool _isRedirecting = false;

//   @override
//   void initState() {
//     super.initState();

//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);

//     _scheduleProgressiveBots();
//   }

//   /// 🕰️ Programme l'arrivée des robots de manière asynchrone et espacée
//   void _scheduleProgressiveBots() {
//     final random = Random();

//     // Robot 1 : Arrive entre 8 et 14 secondes
//     _secondsDelay(random.nextInt(6) + 8, () {
//       _lobbyService.addSingleBot(widget.lobbyId);
//     });

//     // Robot 2 : Arrive entre 20 et 28 secondes
//     _secondsDelay(random.nextInt(8) + 20, () {
//       _lobbyService.addSingleBot(widget.lobbyId);
//     });

//     // Robot 3 (Sécurité) : Arrive entre 38 et 45 secondes pour boucher les trous si nécessaire
//     _secondsDelay(random.nextInt(7) + 38, () {
//       _lobbyService.addSingleBot(widget.lobbyId);
//     });
//   }

//   /// Fonction utilitaire pour ajouter un timer facilement et s'en souvenir pour le dispose
//   void _secondsDelay(int seconds, Function action) {
//     Timer timer = Timer(Duration(seconds: seconds), () async {
//       if (mounted && !_isRedirecting) {
//         await action();
//       }
//     });
//     _activeTimers.add(timer);
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);

//     // 🛑 On détruit TOUS les timers programmés d'un coup pour éviter les bugs en arrière-plan
//     for (var timer in _activeTimers) {
//       timer.cancel();
//     }
//     super.dispose();
//   }

//   void _navigateToCompetition() {
//     if (_isRedirecting) return;
//     _isRedirecting = true;

//     // Coupe tous les minuteurs d'injection puisque la partie se lance
//     for (var timer in _activeTimers) {
//       timer.cancel();
//     }

//     Timer(const Duration(seconds: 3), () {
//       if (mounted) {
//         context.go('/competition?roomId=${widget.lobbyId}');
//       }
//     });
//   }

//   Widget _buildPlayerSlot(List<dynamic> players, int index) {
//     if (index < players.length) {
//       var player = players[index] as Map<String, dynamic>;
//       String nickname = player['nickname'] ?? 'Joueur';
//       String avatarId = player['avatarId'] ?? 'avatar_1';

//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.purple.withAlpha(30),
//               child: Padding(
//                 padding: const EdgeInsets.all(4.0),
//                 child: Image.asset(
//                   'assets/avatars/$avatarId.png',
//                   fit: BoxFit.contain,
//                   errorBuilder: (context, error, stackTrace) =>
//                       const Icon(Icons.person, size: 30, color: Colors.purple),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 4),
//             SizedBox(
//               width: 90,
//               child: Text(
//                 nickname,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//       );
//     } else {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.grey[300],
//               child: const Icon(Icons.add, size: 24, color: Colors.white),
//             ),
//             const SizedBox(height: 4),
//             const Text(
//               "En attente...",
//               style: TextStyle(color: Colors.grey, fontSize: 11),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5E6E8),
//       body: StreamBuilder<DocumentSnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('lobbies')
//             .doc(widget.lobbyId)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting &&
//               !snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || !snapshot.data!.exists) {
//             return const Center(
//               child: Text("Erreur : Impossible de charger la salle."),
//             );
//           }

//           var lobbyData = snapshot.data!.data() as Map<String, dynamic>;
//           int count = lobbyData['playerCount'] ?? 0;
//           String status = lobbyData['status'] ?? 'waiting';
//           List<dynamic> players = lobbyData['players'] ?? [];

//           final bool isReady = status == 'playing' || count >= 4;

//           if (isReady) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               _navigateToCompetition();
//             });
//           }

//           return SafeArea(
//             child: Stack(
//               children: [
//                 // ⏱️ 1. LE TIMER EN HAUT
//                 Align(
//                   alignment: Alignment.topCenter,
//                   child: Padding(
//                     padding: const EdgeInsets.only(top: 12.0),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.purple.withAlpha(40),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: isReady
//                               ? const Text(
//                                   "Match trouvé ! Préparation...",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.purple,
//                                   ),
//                                 )
//                               : const CountdownText(),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           isReady
//                               ? "Début de la compétition imminent !"
//                               : "Recherche d'autres stylistes...",
//                           style: const TextStyle(
//                             fontSize: 13,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // 2. LA DISPOSITION HORIZONTALE (ROW)
//                 Center(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 40.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             _buildPlayerSlot(players, 0),
//                             const SizedBox(height: 10),
//                             _buildPlayerSlot(players, 1),
//                           ],
//                         ),
//                         Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             SizedBox(
//                               width: 110,
//                               height: 110,
//                               child: CircularProgressIndicator(
//                                 value: count / 4,
//                                 strokeWidth: 8,
//                                 backgroundColor: Colors.grey[300],
//                                 valueColor: const AlwaysStoppedAnimation<Color>(
//                                   Colors.purple,
//                                 ),
//                               ),
//                             ),
//                             Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   "$count / 4",
//                                   style: const TextStyle(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 if (!isReady)
//                                   const SizedBox(
//                                     width: 14,
//                                     height: 14,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 1.5,
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             _buildPlayerSlot(players, 2),
//                             const SizedBox(height: 10),
//                             _buildPlayerSlot(players, 3),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// /// ⏱️ LE COMPTE À REBOURS AUTONOME DU HAUT
// class CountdownText extends StatefulWidget {
//   const CountdownText({super.key});

//   @override
//   State<CountdownText> createState() => _CountdownTextState();
// }

// class _CountdownTextState extends State<CountdownText> {
//   int _secondsRemaining = 60;
//   Timer? _ticker;

//   @override
//   void initState() {
//     super.initState();
//     _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) {
//         setState(() {
//           if (_secondsRemaining > 0) {
//             _secondsRemaining--;
//           } else {
//             _ticker?.cancel();
//           }
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _ticker?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       "Lancement dans : $_secondsRemaining s",
//       style: const TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//         color: Colors.purple,
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashion_room_girls/data/services/lobbyService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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

  // Widget pour chaque emplacement de joueur
  Widget _buildPlayerSlot(List<dynamic> players, int index) {
    bool hasPlayer = index < players.length;
    var player = hasPlayer ? players[index] as Map<String, dynamic> : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: hasPlayer ? Colors.purple : Colors.white.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: hasPlayer
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.black12,
            child: hasPlayer
                ? Image.asset('assets/avatars/${player!['avatarId']}.png')
                : const Icon(Icons.add, color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          hasPlayer ? player!['nickname'] : "Attente...",
          style: TextStyle(
            color: hasPlayer ? Colors.purple[800] : Colors.black38,
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
        // 🖼️ IMAGE DE BACKGROUND
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background_lobby.png'), // TON IMAGE ICI
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
              return const Center(child: Text("Salle introuvable"));
            }

            var lobbyData = snapshot.data!.data() as Map<String, dynamic>;
            int count = lobbyData['playerCount'] ?? 0;
            String status = lobbyData['status'] ?? 'waiting';
            List<dynamic> players = lobbyData['players'] ?? [];
            bool isReady = (status == 'playing' || count >= 4);

            if (isReady) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _navigateToCompetition(),
              );
            }

            return Center(
              // 🃏 CARTE SEMI-TRANSPARENTE
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.85,
                  ), // Transparence de la carte
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    // ⏱️ TIMER
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: isReady
                          ? const Text(
                              "PRÊT ! Lancement...",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            )
                          : const CountdownText(),
                    ),
                    const Spacer(),
                    // 📐 ROW PRINCIPALE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // GAUCHE
                        Column(
                          children: [
                            _buildPlayerSlot(players, 0),
                            const SizedBox(height: 15),
                            _buildPlayerSlot(players, 1),
                          ],
                        ),
                        // CENTRE
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: count / 4,
                                strokeWidth: 8,
                                backgroundColor: Colors.purple.withValues(alpha: 0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.purple,
                                ),
                              ),
                            ),
                            Text(
                              "$count / 4",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // DROITE
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
                    const Text(
                      "Recherche de stylistes...",
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Widget de texte pour le chrono (isole le setState)
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
      "Départ dans : $_seconds s",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.purple,
        fontSize: 16,
      ),
    );
  }
}
