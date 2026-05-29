// // import 'dart:async';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';

// // class PlayZoneScreen extends StatefulWidget {
// //   final String roomId;

// //   const PlayZoneScreen({super.key, required this.roomId});

// //   @override
// //   State<PlayZoneScreen> createState() => _PlayZoneScreenState();
// // }

// // class _PlayZoneScreenState extends State<PlayZoneScreen> {
// //   // 3 minutes = 180 secondes
// //   int _secondsLeft = 180;
// //   Timer? _timer;
// //   bool _isSubmitting = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _startCompetitionTimer();
// //   }

// //   // 1. Gestion du Chronomètre de 3 minutes
// //   void _startCompetitionTimer() {
// //     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
// //       if (_secondsLeft > 1) {
// //         setState(() {
// //           _secondsLeft--;
// //         });
// //       } else {
// //         _timer?.cancel();
// //         // 🚨 LE TEMPS EST ÉCOULÉ : Soumission automatique forcée !
// //         _submitOutfit(isAuto: true);
// //       }
// //     });
// //   }

// //   // 2. Fonction pour transformer les secondes en format "02:45"
// //   String _formatTime(int totalSeconds) {
// //     int minutes = totalSeconds ~/ 60;
// //     int seconds = totalSeconds % 60;
// //     // padLeft(2, '0') permet d'écrire "05" au lieu de "5"
// //     return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
// //   }

// //   // 3. Action de Soumission (Manuelle ou Automatique)
// //   Future<void> _submitOutfit({required bool isAuto}) async {
// //     if (_isSubmitting) return; // Évite les doubles clics

// //     setState(() {
// //       _isSubmitting = true;
// //     });
// //     _timer?.cancel(); // On arrête le chrono

// //     try {
// //       // ICI : Plus tard, tu récupéreras le look final créé par ton camarade.
// //       // Pour l'instant, on simule l'enregistrement de la tenue.
// //       String monUserId = "uid_fadma_123";

// //       await FirebaseFirestore.instance
// //           .collection('lobbies')
// //           .doc(widget.roomId)
// //           .collection('submitted_outfits') // Sous-collection pour les créations
// //           .doc(monUserId)
// //           .set({
// //             'userId': monUserId,
// //             'outfitData': 'Design_de_ma_poupée_ici', // Ce que ton ami va coder
// //             'submittedAt': FieldValue.serverTimestamp(),
// //             'finishedInTime': !isAuto, // Pour savoir si elle a fini d'elle-même
// //           });

// //       if (mounted) {
// //         // Alerte visuelle pour confirmer la validation
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               isAuto
// //                   ? "Temps écoulé ! Votre tenue a été sauvegardée automatiquement."
// //                   : "Félicitations ! Tenue enregistrée avec succès.",
// //             ),
// //             backgroundColor: isAuto ? Colors.orange : Colors.green,
// //           ),
// //         );

// //         // 4. Direction l'écran suivant (La zone de Vote / Notation)
// //         context.go('/voting-zone?roomId=${widget.roomId}');
// //       }
// //     } catch (e) {
// //       print("Erreur lors de la soumission de la tenue : $e");
// //       setState(() {
// //         _isSubmitting = false;
// //       });
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _timer?.cancel(); // Sécurité anti-fuite mémoire
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(
// //         0xFFFBF4F5,
// //       ), // Fond neutre pour bien voir la poupée
// //       appBar: AppBar(
// //         backgroundColor: Colors.purple[100],
// //         elevation: 0,
// //         automaticallyImplyLeading:
// //             false, // Empêche le bouton retour arrière pendant le jeu
// //         title: Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             // Affichage du Timer avec un design d'alerte (devient rouge s'il reste moins de 30s)
// //             Row(
// //               children: [
// //                 Icon(
// //                   Icons.timer,
// //                   color: _secondsLeft < 30 ? Colors.red : Colors.purple[900],
// //                 ),
// //                 const SizedBox(width: 8),
// //                 Text(
// //                   _formatTime(_secondsLeft),
// //                   style: TextStyle(
// //                     fontSize: 22,
// //                     fontWeight: FontWeight.bold,
// //                     color: _secondsLeft < 30 ? Colors.red : Colors.purple[900],
// //                   ),
// //                 ),
// //               ],
// //             ),

// //             // Le bouton de Soumission (Submit)
// //             _isSubmitting
// //                 ? const SizedBox(
// //                     width: 24,
// //                     height: 24,
// //                     child: CircularProgressIndicator(strokeWidth: 2),
// //                   )
// //                 : ElevatedButton.icon(
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.green[600],
// //                       foregroundColor: Colors.white,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(20),
// //                       ),
// //                     ),
// //                     onPressed: () => _submitOutfit(isAuto: false),
// //                     icon: const Icon(Icons.check_circle_outline, size: 18),
// //                     label: const Text("Soumettre"),
// //                   ),
// //           ],
// //         ),
// //       ),
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             // Espace de notification / Thème en cours rappeler en haut
// //             Container(
// //               width: double.infinity,
// //               padding: const EdgeInsets.all(8),
// //               color: Colors.purple[50],
// //               child: const Text(
// //                 "Rappel du thème : Créez la plus belle tenue !",
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(
// //                   fontStyle: FontStyle.italic,
// //                   color: Colors.purple,
// //                 ),
// //               ),
// //             ),

// //             // LA ZONE DE TON CAMARADE :
// //             Expanded(
// //               child: Container(
// //                 margin: const EdgeInsets.all(16),
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(12),
// //                   border: Border.all(color: Colors.grey[300]!),
// //                 ),
// //                 child: const Center(
// //                   child: Text(
// //                     "--- [ ICI : LA POUPEE ET SES VETEMENTS ] ---\n(Zone codée par ton camarade d'équipe)",
// //                     textAlign: TextAlign.center,
// //                     style: TextStyle(
// //                       color: Colors.grey,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // import 'dart:async';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';

// // class PlayZoneScreen extends StatefulWidget {
// //   final String roomId;
// //   // À récupérer idéalement depuis ton State Management / Auth (ex: FirebaseAuth.instance.currentUser!.uid)
// //   final String currentUserId;

// //   const PlayZoneScreen({
// //     super.key,
// //     required this.roomId,
// //     this.currentUserId = "uid_fadma_123", // Valeur par défaut temporaire
// //   });

// //   @override
// //   State<PlayZoneScreen> createState() => _PlayZoneScreenState();
// // }

// // class _PlayZoneScreenState extends State<PlayZoneScreen> {
// //   int _secondsLeft = 180; // 3 minutes
// //   Timer? _timer;
// //   bool _isSubmitting = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _startCompetitionTimer();
// //   }

// //   void _startCompetitionTimer() {
// //     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
// //       if (_secondsLeft > 1) {
// //         setState(() {
// //           _secondsLeft--;
// //         });
// //       } else {
// //         _timer?.cancel();
// //         _submitOutfit(isAuto: true);
// //       }
// //     });
// //   }

// //   String _formatTime(int totalSeconds) {
// //     int minutes = totalSeconds ~/ 60;
// //     int seconds = totalSeconds % 60;
// //     return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
// //   }

// //   // 🎯 ACTION DE SOUMISSION AVEC GESTION DES BOTS
// //   Future<void> _submitOutfit({required bool isAuto}) async {
// //     if (_isSubmitting) return;

// //     setState(() {
// //       _isSubmitting = true;
// //     });
// //     _timer?.cancel();

// //     try {
// //       final firestore = FirebaseFirestore.instance;
// //       final lobbyRef = firestore.collection('lobbies').doc(widget.roomId);

// //       // 1. 👗 RÉCUPÉRATION DES DONNÉES DU JOUEUR HUMAIN
// //       // (Ici ton camarade te passera la liste des accessoires ou le lien de l'image finale)
// //       Map<String, dynamic> myOutfitData = {
// //         'characterBase': 'skin_light',
// //         'clothes': ['dress_chic_01', 'shoes_gold_03'],
// //         'hair': 'hair_blonde_long',
// //       };

// //       // 2. Enregistrement de la tenue de l'humain
// //       await lobbyRef
// //           .collection('submitted_outfits')
// //           .doc(widget.currentUserId)
// //           .set({
// //             'userId': widget.currentUserId,
// //             'outfitData':
// //                 myOutfitData, // Données structurées passées au système de vote
// //             'submittedAt': FieldValue.serverTimestamp(),
// //             'finishedInTime': !isAuto,
// //             'isBot': false,
// //           });

// //       // 3. 🤖 GESTION DES ROBOTS (Soumission automatique de leurs looks)
// //       // On lit les données du lobby pour voir s'il y a des bots présents
// //       final lobbySnapshot = await lobbyRef.get();
// //       if (lobbySnapshot.exists) {
// //         List<dynamic> players = lobbySnapshot.data()?['players'] ?? [];

// //         // Pour chaque joueur qui est un bot, on soumet sa tenue pré-générée
// //         for (var player in players) {
// //           if (player['isBot'] == true) {
// //             String botUid = player['uid'];
// //             String botDollImage =
// //                 player['dollImage'] ?? 'assets/bots/poupee_chic.png';

// //             // On l'ajoute dans la liste des tenues soumises si elle n'existe pas déjà
// //             await lobbyRef.collection('submitted_outfits').doc(botUid).set(
// //               {
// //                 'userId': botUid,
// //                 // Pour le bot, on transmet directement son image fixe de poupée complète
// //                 'outfitData': {'isBotOutfit': true, 'imageUrl': botDollImage},
// //                 'submittedAt': FieldValue.serverTimestamp(),
// //                 'finishedInTime': true,
// //                 'isBot': true,
// //               },
// //               SetOptions(merge: true),
// //             ); // Évite d'écraser si déjà fait par un autre joueur
// //           }
// //         }
// //       }

// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               isAuto
// //                   ? "Temps écoulé ! Votre tenue a été sauvegardée automatiquement."
// //                   : "Félicitations ! Tenue enregistrée avec succès.",
// //             ),
// //             backgroundColor: isAuto ? Colors.orange : Colors.green,
// //           ),
// //         );

// //         // Direction l'écran suivant (La zone de Vote / Notation)
// //         context.go('/voting-zone?roomId=${widget.roomId}');
// //       }
// //     } catch (e) {
// //       print("Erreur lors de la soumission : $e");
// //       setState(() {
// //         _isSubmitting = false;
// //       });
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _timer?.cancel();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     // Garde ton build intact ici, il est déjà très bien structuré !
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFFBF4F5),
// //       appBar: AppBar(
// //         backgroundColor: Colors.purple[100],
// //         elevation: 0,
// //         automaticallyImplyLeading: false,
// //         title: Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Row(
// //               children: [
// //                 Icon(
// //                   Icons.timer,
// //                   color: _secondsLeft < 30 ? Colors.red : Colors.purple[900],
// //                 ),
// //                 const SizedBox(width: 8),
// //                 Text(
// //                   _formatTime(_secondsLeft),
// //                   style: TextStyle(
// //                     fontSize: 22,
// //                     fontWeight: FontWeight.bold,
// //                     color: _secondsLeft < 30 ? Colors.red : Colors.purple[900],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             _isSubmitting
// //                 ? const SizedBox(
// //                     width: 24,
// //                     height: 24,
// //                     child: CircularProgressIndicator(strokeWidth: 2),
// //                   )
// //                 : ElevatedButton.icon(
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.green[600],
// //                       foregroundColor: Colors.white,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(20),
// //                       ),
// //                     ),
// //                     onPressed: () => _submitOutfit(isAuto: false),
// //                     icon: const Icon(Icons.check_circle_outline, size: 18),
// //                     label: const Text("Soumettre"),
// //                   ),
// //           ],
// //         ),
// //       ),
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             Container(
// //               width: double.infinity,
// //               padding: const EdgeInsets.all(8),
// //               color: Colors.purple[50],
// //               child: const Text(
// //                 "Rappel du thème : Créez la plus belle tenue !",
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(
// //                   fontStyle: FontStyle.italic,
// //                   color: Colors.purple,
// //                 ),
// //               ),
// //             ),
// //             Expanded(
// //               child: Container(
// //                 margin: const EdgeInsets.all(16),
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(12),
// //                   border: Border.all(color: Colors.grey[300]!),
// //                 ),
// //                 child: const Center(
// //                   child: Text(
// //                     "--- [ ICI : LA POUPEE ET SES VETEMENTS ] ---\n(Zone codée par ton camarade d'équipe)",
// //                     textAlign: TextAlign.center,
// //                     style: TextStyle(
// //                       color: Colors.grey,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class PlayZoneScreen extends StatefulWidget {
//   final String roomId;
//   final String currentUserId;

//   const PlayZoneScreen({
//     super.key,
//     required this.roomId,
//     this.currentUserId = "uid_fadma_123", // Valeur par défaut temporaire
//   });

//   @override
//   State<PlayZoneScreen> createState() => _PlayZoneScreenState();
// }

// class _PlayZoneScreenState extends State<PlayZoneScreen> {
//   int _secondsLeft = 180; // 3 minutes
//   Timer? _timer;
//   bool _isSubmitting = false;

//   @override
//   void initState() {
//     super.initState();
//     _startCompetitionTimer();
//   }

//   void _startCompetitionTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_secondsLeft > 1) {
//         setState(() {
//           _secondsLeft--;
//         });
//       } else {
//         _timer?.cancel();
//         _submitOutfit(isAuto: true);
//       }
//     });
//   }

//   String _formatTime(int totalSeconds) {
//     int minutes = totalSeconds ~/ 60;
//     int seconds = totalSeconds % 60;
//     return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
//   }

//   // 🎯 ACTION DE SOUMISSION MODIFIÉE
//   Future<void> _submitOutfit({required bool isAuto}) async {
//     if (_isSubmitting) return;

//     setState(() {
//       _isSubmitting = true;
//     });
//     _timer?.cancel();

//     try {
//       final firestore = FirebaseFirestore.instance;
//       final lobbyRef = firestore.collection('lobbies').doc(widget.roomId);

//       // 1. 👗 RÉCUPÉRATION DES DONNÉES DU JOUEUR HUMAIN
//       Map<String, dynamic> myOutfitData = {
//         'characterBase': 'skin_light',
//         'clothes': ['dress_chic_01', 'shoes_gold_03'],
//         'hair': 'hair_blonde_long',
//       };

//       // 2. Enregistrement de la tenue de l'humain
//      await lobbyRef
//     .collection('submitted_outfits')
//     .doc(widget.currentUserId)
//     .set({
//       'userId': widget.currentUserId,
//       'username': 'fadma', // 👈 AJOUTÉ : Mets ici la variable du pseudo de l'humain
//       'outfitData': myOutfitData,
//       'submittedAt': FieldValue.serverTimestamp(),
//       'finishedInTime': !isAuto,
//       'isBot': false,
//       'votesCount': 0,
//     });

//       // 3. 🤖 GESTION DES ROBOTS
//       final lobbySnapshot = await lobbyRef.get();
//       if (lobbySnapshot.exists) {
//         List<dynamic> players = lobbySnapshot.data()?['players'] ?? [];

//         for (var player in players) {
//          if (player['isBot'] == true) {
//   String botUid = player['uid'];
//   String botName = player['name'] ?? 'Robot Styliste'; // 👈 AJOUTÉ : Récupère le nom du robot (Choupette, etc.)
//   String botDollImage = player['dollImage'] ?? 'assets/bots/poupee_chic.png';

//   await lobbyRef.collection('submitted_outfits').doc(botUid).set(
//     {
//       'userId': botUid,
//       'username': botName, // 👈 AJOUTÉ : On enregistre son vrai nom !
//       'outfitData': {'isBotOutfit': true, 'imageUrl': botDollImage},
//       'submittedAt': FieldValue.serverTimestamp(),
//       'finishedInTime': true,
//       'isBot': true,
//       'votesCount': 0,
//     },
//     SetOptions(merge: true),
//   );
// }
//         }
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               isAuto
//                   ? "Temps écoulé ! Votre tenue a été sauvegardée automatiquement."
//                   : "Félicitations ! Tenue enregistrée avec succès.",
//             ),
//             backgroundColor: isAuto ? Colors.orange : Colors.green,
//           ),
//         );

//         // 4. 👈 MODIFIÉ : On transmet le roomId ET le currentUserId à l'écran de vote !
//         context.go(
//           '/voting-zone?roomId=${widget.roomId}&currentUserId=${widget.currentUserId}',
//         );
//       }
//     } catch (e) {
//       print("Erreur lors de la soumission : $e");
//       setState(() {
//         _isSubmitting = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFBF4F5),
//       appBar: AppBar(
//         backgroundColor: Colors.purple[100],
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   Icons.timer,
//                   color: _secondsLeft < 30 ? Colors.red : Colors.purple[900],
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   _formatTime(_secondsLeft),
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: _secondsLeft < 30 ? Colors.red : Colors.purple[900],
//                   ),
//                 ),
//               ],
//             ),
//             _isSubmitting
//                 ? const SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 : ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green[600],
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                     onPressed: () => _submitOutfit(isAuto: false),
//                     icon: const Icon(Icons.check_circle_outline, size: 18),
//                     label: const Text("Soumettre"),
//                   ),
//           ],
//         ),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(8),
//               color: Colors.purple[50],
//               child: const Text(
//                 "Rappel du thème : Créez la plus belle tenue !",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontStyle: FontStyle.italic,
//                   color: Colors.purple,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 margin: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey[300]!),
//                 ),
//                 child: const Center(
//                   child: Text(
//                     "--- [ ICI : LA POUPEE ET SES VETEMENTS ] ---\n(Zone codée par ton camarade d'équipe)",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.grey,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/character_capture_service.dart';

class PlayZoneScreen extends StatefulWidget {
  final String roomId;
  final String currentUserId;

  const PlayZoneScreen({
    super.key,
    required this.roomId,
    this.currentUserId = "uid_fadma_123", // Valeur par défaut temporaire
  });

  @override
  State<PlayZoneScreen> createState() => _PlayZoneScreenState();
}

class _PlayZoneScreenState extends State<PlayZoneScreen> {
  int _secondsLeft = 180; // 3 minutes
  Timer? _timer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startCompetitionTimer();
  }

  void _startCompetitionTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        _submitOutfit(isAuto: true);
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  // 🎯 ACTION DE SOUMISSION AVEC ENREGISTREMENT DU PSEUDO ET DES BOTS
  Future<void> _submitOutfit({required bool isAuto}) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });
    _timer?.cancel();

    try {
      final firestore = FirebaseFirestore.instance;
      final lobbyRef = firestore.collection('lobbies').doc(widget.roomId);

      // 1. 👗 RÉCUPÉRATION DES DONNÉES DU JOUEUR HUMAIN
      final latestCapture = await CharacterCaptureService().latestCapture();
      Map<String, dynamic> myOutfitData = latestCapture == null
          ? {
        'characterBase': 'skin_light',
        'clothes': ['dress_chic_01', 'shoes_gold_03'],
        'hair': 'hair_blonde_long',
      }
          : {
              ...latestCapture.data,
              'imageUrl': latestCapture.downloadUrl,
            };

      // 2. Enregistrement de la tenue de l'humain avec son pseudo
      await lobbyRef
          .collection('submitted_outfits')
          .doc(widget.currentUserId)
          .set({
            'userId': widget.currentUserId,
            'username': 'fadma', // Variable du pseudo de l'humain
            'outfitData': myOutfitData,
            'submittedAt': FieldValue.serverTimestamp(),
            'finishedInTime': !isAuto,
            'isBot': false,
            'votesCount': 0,
          });

      // 3. 🤖 GESTION DES ROBOTS
      final lobbySnapshot = await lobbyRef.get();
      if (lobbySnapshot.exists) {
        List<dynamic> players = lobbySnapshot.data()?['players'] ?? [];

        for (var player in players) {
          if (player['isBot'] == true) {
            String botUid = player['uid'];
            String botName =
                player['name'] ?? 'Robot Styliste'; // Récupère le nom du robot
            String botDollImage =
                player['dollImage'] ?? 'assets/bots/poupee_chic.png';

            await lobbyRef.collection('submitted_outfits').doc(botUid).set({
              'userId': botUid,
              'username': botName, // On enregistre son vrai nom !
              'outfitData': {'isBotOutfit': true, 'imageUrl': botDollImage},
              'submittedAt': FieldValue.serverTimestamp(),
              'finishedInTime': true,
              'isBot': true,
              'votesCount': 0,
            }, SetOptions(merge: true));
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAuto
                  ? "Temps écoulé ! Votre tenue a été sauvegardée automatiquement."
                  : "Félicitations ! Tenue enregistrée avec succès.",
            ),
            backgroundColor: isAuto ? Colors.orange : Colors.green,
          ),
        );

        // 4. On transmet le roomId ET le currentUserId à l'écran de vote !
        context.go(
          '/voting-zone?roomId=${widget.roomId}&currentUserId=${widget.currentUserId}',
        );
      }
    } catch (e) {
      print("Erreur lors de la soumission : $e");
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF4F5),
      appBar: AppBar(
        backgroundColor: Colors.purple[100],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: _secondsLeft < 30 ? Colors.red : Colors.purple[900],
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_secondsLeft),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _secondsLeft < 30 ? Colors.red : Colors.purple[900],
                  ),
                ),
              ],
            ),
            _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _submitOutfit(isAuto: false),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text("Soumettre"),
                  ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.purple[50],
              child: const Text(
                "Rappel du thème : Créez la plus belle tenue !",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.purple,
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text(
                    "--- [ ICI : LA POUPEE ET SES VETEMENTS ] ---\n(Zone codée par ton camarade d'équipe)",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
