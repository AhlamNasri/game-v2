// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class VotingZoneScreen extends StatefulWidget {
//   final String roomId;

//   const VotingZoneScreen({super.key, required this.roomId});

//   @override
//   State<VotingZoneScreen> createState() => _VotingZoneScreenState();
// }

// class _VotingZoneScreenState extends State<VotingZoneScreen> {
//   // TODO: À remplacer plus tard par le vrai ID de la joueuse connectée
//   final String currentUserId = "uid_fadma_123";
//   bool _hasVoted = false; // Pour bloquer le vote après le premier clic

//   // Fonction magique qui s'exécute quand on clique sur la meilleure poupée
//   Future<void> _voteForOutfit(String opponentId) async {
//     if (_hasVoted) return; // Sécurité : impossible de voter deux fois !

//     setState(() {
//       _hasVoted = true;
//     });

//     try {
//       // On va directement ajouter +1 vote sur le document de l'adversaire choisi
//       await FirebaseFirestore.instance
//           .collection('lobbies')
//           .doc(widget.roomId)
//           .collection('submitted_outfits')
//           .doc(opponentId)
//           .update({'votesCount': FieldValue.increment(1)});

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Vote enregistré ! En attente des résultats..."),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       print("Erreur lors du vote : $e");
//       setState(() {
//         _hasVoted = false; // En cas de bug réseau, on réactive le bouton
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF3EEF5),
//       appBar: AppBar(
//         title: const Text("Votez pour le meilleur Look !"),
//         backgroundColor: Colors.purple[700],
//         foregroundColor: Colors.white,
//         automaticallyImplyLeading: false,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('lobbies')
//             .doc(widget.roomId)
//             .collection('submitted_outfits')
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("Chargement des créations..."));
//           }

//           // 1. Filtrage crucial : On ENLÈVE ta propre poupée de la liste !
//           final opponentsOutfits = snapshot.data!.docs.where((doc) {
//             return doc.id !=
//                 currentUserId; // doc.id correspond à l'id du créateur
//           }).toList();

//           if (opponentsOutfits.isEmpty) {
//             return const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(24.0),

//                 child: Text(
//                   "En attente de l'arrivée des poupées de vos adversaires...",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
//                 ),
//               ),
//             );
//           }

//           return Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   _hasVoted
//                       ? "Merci d'avoir voté ! Regardez les looks :"
//                       : "Cliquez sur la plus belle poupée parmi vos rivales :",
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.purple,
//                   ),
//                 ),
//               ),
//               Expanded(
//                 // On affiche les adversaires côte à côte ou en liste
//                 child: ListView.builder(
//                   itemCount: opponentsOutfits.length,
//                   itemBuilder: (context, index) {
//                     var outfitData =
//                         opponentsOutfits[index].data() as Map<String, dynamic>;
//                     String opponentId = opponentsOutfits[index].id;

//                     return Card(
//                       margin: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 8,
//                       ),
//                       elevation: 4,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(16),
//                         // Si on n'a pas encore voté, on peut cliquer sur la carte entière !
//                         onTap: _hasVoted
//                             ? null
//                             : () => _voteForOutfit(opponentId),
//                         child: Container(
//                           padding: const EdgeInsets.all(16.0),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(
//                               color: _hasVoted
//                                   ? Colors.transparent
//                                   : Colors.purple.withOpacity(0.2),
//                               width: 2,
//                             ),
//                           ),
//                           child: Row(
//                             children: [
//                               // Zone visuelle de la poupée
//                               Container(
//                                 width: 80,
//                                 height: 100,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[100],
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: const Icon(
//                                   Icons.accessibility_new,
//                                   size: 40,
//                                   color: Colors.pink,
//                                 ),
//                               ),
//                               const SizedBox(width: 16),

//                               // Informations de l'adversaire
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       "Styliste : Concurrente ${index + 1}",
//                                       style: const TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     const Text(
//                                       "👗 Cliquez pour choisir ce look",
//                                       style: TextStyle(
//                                         color: Colors.grey,
//                                         fontSize: 13,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),

//                               // Une petite icône de coche si on clique dessus
//                               if (!_hasVoted)
//                                 const Icon(
//                                   Icons.arrow_forward_ios,
//                                   color: Colors.purple,
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class VotingZoneScreen extends StatefulWidget {
//   final String roomId;
//   final String currentUserId;

//   const VotingZoneScreen({
//     super.key,
//     required this.roomId,
//     this.currentUserId = "uid_fadma_123", // Id utilisateur par défaut
//   });

//   @override
//   State<VotingZoneScreen> createState() => _VotingZoneScreenState();
// }

// class _VotingZoneScreenState extends State<VotingZoneScreen> {
//   bool _hasVoted = false;

//   Future<void> _voteForOutfit(String opponentId) async {
//     if (_hasVoted) return;

//     setState(() {
//       _hasVoted = true;
//     });

//     try {
//       await FirebaseFirestore.instance
//           .collection('lobbies')
//           .doc(widget.roomId)
//           .collection('submitted_outfits')
//           .doc(opponentId)
//           .update({'votesCount': FieldValue.increment(1)});

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               "✨ Vote pris en compte ! En attente des résultats globaux...",
//             ),
//             backgroundColor: Colors.pinkAccent,
//           ),
//         );
//       }
//     } catch (e) {
//       print("Erreur lors du vote : $e");
//       setState(() {
//         _hasVoted = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFDF8F5), // Fond doux assorti au lobby
//       appBar: AppBar(
//         title: const Text(
//           "Qui a le meilleur Look ?",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: const Color(0xFFDCA1A7),
//         foregroundColor: Colors.white,
//         automaticallyImplyLeading: false,
//         centerTitle: true,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('lobbies')
//             .doc(widget.roomId)
//             .collection('submitted_outfits')
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDCA1A7)),
//               ),
//             );
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text(
//                 "Préparation du défilé...",
//                 style: TextStyle(color: Color(0xFF704E52)),
//               ),
//             );
//           }

//           // Filtrage pour ne pas voter pour soi-même
//           final opponentsOutfits = snapshot.data!.docs.where((doc) {
//             return doc.id != widget.currentUserId;
//           }).toList();

//           if (opponentsOutfits.isEmpty) {
//             return const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(24.0),
//                 child: Text(
//                   "Les autres stylistes finalisent leurs tenues... Suspense ! 👑",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontStyle: FontStyle.italic,
//                     color: Color(0xFF704E52),
//                   ),
//                 ),
//               ),
//             );
//           }

//           return Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   _hasVoted
//                       ? "Merci pour votre vote ! Que la meilleure gagne 👑"
//                       : "Sélectionnez la création la plus tendance :",
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF704E52),
//                   ),
//                 ),
//               ),

//               // 📱 Affichage sous forme de Grille pour mieux voir les mannequins côte à côte
//               Expanded(
//                 child: GridView.builder(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 8,
//                   ),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2, // 2 mannequins par ligne
//                     crossAxisSpacing: 14,
//                     mainAxisSpacing: 14,
//                     childAspectRatio:
//                         0.75, // Ajuste le ratio hauteur/largeur de la carte
//                   ),
//                   itemCount: opponentsOutfits.length,
//                   itemBuilder: (context, index) {
//                     var submittedData =
//                         opponentsOutfits[index].data() as Map<String, dynamic>;
//                     String opponentId = opponentsOutfits[index].id;

//                     bool isBot = submittedData['isBot'] ?? false;
//                     var outfitData =
//                         submittedData['outfitData'] as Map<String, dynamic>?;

//                     return Card(
//                       elevation: 3,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       clipBehavior: Clip.antiAlias,
//                       child: InkWell(
//                         onTap: _hasVoted
//                             ? null
//                             : () => _voteForOutfit(opponentId),
//                         child: Column(
//                           children: [
//                             // 👗 ZONE DU MANNEQUIN
//                             Expanded(
//                               child: Container(
//                                 width: double.infinity,
//                                 color: Colors.white,
//                                 child: isBot
//                                     ? Image.asset(
//                                         outfitData?['imageUrl'] ??
//                                             'assets/bots/poupee_chic.png',
//                                         fit: BoxFit.contain,
//                                       )
//                                     : Center(
//                                         // 👤 ZONE DE TON CAMARADE D'ÉQUIPE (Humain)
//                                         child: Column(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             const Icon(
//                                               Icons.checkroom,
//                                               size: 40,
//                                               color: Color(0xFFDCA1A7),
//                                             ),
//                                             const SizedBox(height: 5),
//                                             Text(
//                                               "Look Humain\n(${outfitData?['hair'] ?? 'Standard'})",
//                                               textAlign: TextAlign.center,
//                                               style: const TextStyle(
//                                                 fontSize: 12,
//                                                 color: Colors.grey,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                               ),
//                             ),

//                             // 🏷️ BAS DE CARTE (Nom / Statut du vote)
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 vertical: 8,
//                                 horizontal: 12,
//                               ),
//                               color: const Color(0xFFFDF8F5),
//                               width: double.infinity,
//                               child: Column(
//                                 children: [
//                                   Text(
//                                     isBot ? "Modèle Virtuel" : "Styliste Réel",
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 13,
//                                       color: Color(0xFF704E52),
//                                     ),
//                                   ),
//                                   if (!_hasVoted) ...[
//                                     const SizedBox(height: 4),
//                                     const Text(
//                                       "💖 Voter",
//                                       style: TextStyle(
//                                         color: Colors.pinkAccent,
//                                         fontSize: 11,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class VotingZoneScreen extends StatefulWidget {
//   final String roomId;
//   final String currentUserId;

//   const VotingZoneScreen({
//     super.key,
//     required this.roomId,
//     this.currentUserId = "uid_fadma_123",
//   });

//   @override
//   State<VotingZoneScreen> createState() => _VotingZoneScreenState();
// }

// class _VotingZoneScreenState extends State<VotingZoneScreen> {
//   bool _hasVoted = false;

//   // 👑 VOTE DE L'HUMAIN + COMPORTEMENT DES ROBOTS
//   Future<void> _voteForOutfit(String opponentId) async {
//     if (_hasVoted) return;

//     setState(() {
//       _hasVoted = true;
//     });

//     try {
//       final firestore = FirebaseFirestore.instance;
//       final submittedOutfitsRef = firestore
//           .collection('lobbies')
//           .doc(widget.roomId)
//           .collection('submitted_outfits');

//       // 1. On applique ton vote sur Firebase
//       await submittedOutfitsRef.doc(opponentId).update({
//         'votesCount': FieldValue.increment(1),
//       });

//       // 2. 🤖 CHAQUE ROBOT CHOISIT UNE CIBLE AU HASARD (SAUF LUI-MÊME)
//       final outfitsSnapshot = await submittedOutfitsRef.get();
//       final allOutfits = outfitsSnapshot.docs;
//       final random = Random();

//       for (var botDoc in allOutfits) {
//         Map<String, dynamic> botData = botDoc.data();

//         if (botData['isBot'] == true) {
//           String botUid = botDoc.id;

//           // Le robot filtre la liste pour ne pas voter pour lui-même !
//           List<String> validTargets = allOutfits
//               .where((doc) => doc.id != botUid)
//               .map((doc) => doc.id)
//               .toList();

//           if (validTargets.isNotEmpty) {
//             String chosenTargetId =
//                 validTargets[random.nextInt(validTargets.length)];

//             await submittedOutfitsRef.doc(chosenTargetId).update({
//               'votesCount': FieldValue.increment(1),
//             });
//             print("🤖 Le robot [$botUid] a voté pour [$chosenTargetId]");
//           }
//         }
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("✨ Votes enregistrés ! Préparation du podium..."),
//             backgroundColor: Colors.pinkAccent,
//           ),
//         );
//       }
//     } catch (e) {
//       print("Erreur lors du vote : $e");
//       setState(() {
//         _hasVoted = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFDF8F5),
//       appBar: AppBar(
//         title: const Text(
//           "Qui a le meilleur Look ?",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: const Color(0xFFDCA1A7),
//         foregroundColor: Colors.white,
//         automaticallyImplyLeading: false,
//         centerTitle: true,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('lobbies')
//             .doc(widget.roomId)
//             .collection('submitted_outfits')
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDCA1A7)),
//               ),
//             );
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(
//               child: Text(
//                 "Chargement des créations...",
//                 style: TextStyle(color: Color(0xFF704E52)),
//               ),
//             );
//           }

//           // Filtrage pour cacher ta propre création
//           final opponentsOutfits = snapshot.data!.docs.where((doc) {
//             return doc.id != widget.currentUserId;
//           }).toList();

//           if (opponentsOutfits.isEmpty) {
//             return const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(24.0),
//                 child: Text(
//                   "En attente de la validation des autres stylistes... 👑",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontStyle: FontStyle.italic,
//                     color: Color(0xFF704E52),
//                   ),
//                 ),
//               ),
//             );
//           }

//           return Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   _hasVoted
//                       ? "Merci pour votre vote ! Calcul des scores..."
//                       : "Sélectionnez le look le plus stylé :",
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF704E52),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: GridView.builder(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 8,
//                   ),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     crossAxisSpacing: 14,
//                     mainAxisSpacing: 14,
//                     childAspectRatio:
//                         0.72, // Un poil plus vertical pour bien voir les tenues de la tête aux pieds
//                   ),
//                   itemCount: opponentsOutfits.length,
//                   itemBuilder: (context, index) {
//                     var submittedData =
//                         opponentsOutfits[index].data() as Map<String, dynamic>;
//                     String opponentId = opponentsOutfits[index].id;

//                     bool isBot = submittedData['isBot'] ?? false;
//                     var outfitData =
//                         submittedData['outfitData'] as Map<String, dynamic>?;

//                     return Card(
//                       elevation: 3,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       clipBehavior: Clip.antiAlias,
//                       child: InkWell(
//                         onTap: _hasVoted
//                             ? null
//                             : () => _voteForOutfit(opponentId),
//                         child: Column(
//                           children: [
//                             // 👗 AFFICHAGE DU MANNEQUIN DE LA RIVALE
//                             Expanded(
//                               child: Container(
//                                 width: double.infinity,
//                                 color: Colors.white,
//                                 child: isBot
//                                     ? Image.asset(
//                                         outfitData?['imageUrl'] ??
//                                             'assets/bots/poupee_chic.png',
//                                         fit: BoxFit
//                                             .contain, // Évite que les pieds ou les cheveux de la poupée soient coupés
//                                       )
//                                     : Center(
//                                         // Zone temporaire pour l'humain avant que ton ami ne branche son widget
//                                         child: Column(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             const Icon(
//                                               Icons.checkroom,
//                                               size: 40,
//                                               color: Color(0xFFDCA1A7),
//                                             ),
//                                             const SizedBox(height: 5),
//                                             Text(
//                                               "Look Humain\n(${outfitData?['hair'] ?? 'Standard'})",
//                                               textAlign: TextAlign.center,
//                                               style: const TextStyle(
//                                                 fontSize: 12,
//                                                 color: Colors.grey,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                               ),
//                             ),

//                             // 🏷️ PIED DE LA CARTE
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 vertical: 8,
//                                 horizontal: 12,
//                               ),
//                               color: const Color(0xFFFDF8F5),
//                               width: double.infinity,
//                               child: Column(
//                                 children: [
//                                   Text(
//                                     isBot ? "Modèle Virtuel" : "Styliste Réel",
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 13,
//                                       color: Color(0xFF704E52),
//                                     ),
//                                   ),
//                                   if (!_hasVoted) ...[
//                                     const SizedBox(height: 4),
//                                     const Text(
//                                       "💖 Voter",
//                                       style: TextStyle(
//                                         color: Colors.pinkAccent,
//                                         fontSize: 11,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

import 'dart:async'; // 👈 MODIFICATION : Import indispensable pour le Timer
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 👈 MODIFICATION : Import pour la navigation

class VotingZoneScreen extends StatefulWidget {
  final String roomId;
  final String
  currentUserId; // 👈 Enlevé le "=" en dur d'ici pour plus de flexibilité

  const VotingZoneScreen({
    super.key,
    required this.roomId,
    required this.currentUserId, // 👈 MODIFICATION : Requis pour garder le bon joueur connecté
  });

  @override
  State<VotingZoneScreen> createState() => _VotingZoneScreenState();
}

class _VotingZoneScreenState extends State<VotingZoneScreen> {
  bool _hasVoted = false;

  // 👑 VOTE DE L'HUMAIN + COMPORTEMENT DES ROBOTS
  Future<void> _voteForOutfit(String opponentId) async {
    if (_hasVoted) return;

    setState(() {
      _hasVoted = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final submittedOutfitsRef = firestore
          .collection('lobbies')
          .doc(widget.roomId)
          .collection('submitted_outfits');

      // 1. On applique ton vote sur Firebase
      await submittedOutfitsRef.doc(opponentId).update({
        'votesCount': FieldValue.increment(1),
      });

      // 2. 🤖 CHAQUE ROBOT CHOISIT UNE CIBLE AU HASARD (SAUF LUI-MÊME)
      final outfitsSnapshot = await submittedOutfitsRef.get();
      final allOutfits = outfitsSnapshot.docs;
      final random = Random();

      for (var botDoc in allOutfits) {
        Map<String, dynamic> botData = botDoc.data();

        if (botData['isBot'] == true) {
          String botUid = botDoc.id;

          // Le robot filtre la liste pour ne pas voter pour lui-même !
          List<String> validTargets = allOutfits
              .where((doc) => doc.id != botUid)
              .map((doc) => doc.id)
              .toList();

          if (validTargets.isNotEmpty) {
            String chosenTargetId =
                validTargets[random.nextInt(validTargets.length)];

            await submittedOutfitsRef.doc(chosenTargetId).update({
              'votesCount': FieldValue.increment(1),
            });
            print("🤖 Le robot [$botUid] a voté pour [$chosenTargetId]");
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✨ Votes enregistrés ! Préparation du podium..."),
            backgroundColor: Colors.pinkAccent,
          ),
        );

        // 3. 👈 MODIFICATION : Redirection automatique vers l'écran des résultats après 2 secondes
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/result-zone?roomId=${widget.roomId}');
          }
        });
      }
    } catch (e) {
      print("Erreur lors du vote : $e");
      setState(() {
        _hasVoted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        title: const Text(
          "Qui a le meilleur Look ?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFDCA1A7),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lobbies')
            .doc(widget.roomId)
            .collection('submitted_outfits')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDCA1A7)),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Chargement des créations...",
                style: TextStyle(color: Color(0xFF704E52)),
              ),
            );
          }

          // Filtrage pour cacher ta propre création
          final opponentsOutfits = snapshot.data!.docs.where((doc) {
            return doc.id !=
                widget
                    .currentUserId; // 👈 Utilise maintenant widget.currentUserId
          }).toList();

          if (opponentsOutfits.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "En attente de la validation des autres stylistes... 👑",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF704E52),
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _hasVoted
                      ? "Merci pour votre vote ! Calcul des scores..."
                      : "Sélectionnez le look le plus stylé :",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF704E52),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: opponentsOutfits.length,
                  itemBuilder: (context, index) {
                    var submittedData =
                        opponentsOutfits[index].data() as Map<String, dynamic>;
                    String opponentId = opponentsOutfits[index].id;

                    bool isBot = submittedData['isBot'] ?? false;
                    var outfitData =
                        submittedData['outfitData'] as Map<String, dynamic>?;

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _hasVoted
                            ? null
                            : () => _voteForOutfit(opponentId),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                color: Colors.white,
                                child: isBot
                                    ? Image.asset(
                                        outfitData?['imageUrl'] ??
                                            'assets/bots/poupee_chic.png',
                                        fit: BoxFit.contain,
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.checkroom,
                                              size: 40,
                                              color: Color(0xFFDCA1A7),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              "Look Humain\n(${outfitData?['hair'] ?? 'Standard'})",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              color: const Color(0xFFFDF8F5),
                              width: double.infinity,
                              child: Column(
                                children: [
                                  Text(
                                    isBot ? "Modèle Virtuel" : "Styliste Réel",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF704E52),
                                    ),
                                  ),
                                  if (!_hasVoted) ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      "💖 Voter",
                                      style: TextStyle(
                                        color: Colors.pinkAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
