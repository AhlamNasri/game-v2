// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class ResultZoneScreen extends StatelessWidget {
//   final String roomId;

//   const ResultZoneScreen({super.key, required this.roomId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFDF8F5), // Même fond doux
//       appBar: AppBar(
//         title: const Text(
//           "🏆 RÉSULTATS DU DÉFILÉ 🏆",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: const Color(0xFFDCA1A7),
//         foregroundColor: Colors.white,
//         automaticallyImplyLeading: false,
//         centerTitle: true,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         // On récupère les tenues triées par le plus grand nombre de votes d'abord !
//         stream: FirebaseFirestore.instance
//             .collection('lobbies')
//             .doc(roomId)
//             .collection('submitted_outfits')
//             .orderBy('votesCount', descending: true)
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
//                 "Calcul des scores finaux...",
//                 style: TextStyle(color: Color(0xFF704E52), fontSize: 16),
//               ),
//             );
//           }

//           final podiumList = snapshot.data!.docs;

//           // On récupère les infos du grand gagnant (Le premier de la liste)
//           var winnerData = podiumList[0].data() as Map<String, dynamic>;
//           bool winnerIsBot = winnerData['isBot'] ?? false;
//           int winnerVotes = winnerData['votesCount'] ?? 0;

//           return SafeArea(
//             child: Column(
//               children: [
//                 const SizedBox(height: 15),

//                 // 🎉 TEXTE D'ANIMATION DU VAINQUEUR
//                 const Text(
//                   "✨ ET LA GAGNANTE EST ✨",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF704E52),
//                     letterSpacing: 2,
//                   ),
//                 ),

//                 // 👑 AFFICHAGE EN GRAND DE LA POUPÉE GAGNANTE
//                 Expanded(
//                   flex: 5,
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(
//                       horizontal: 30,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(24),
//                       boxShadow: [
//                         BoxShadow(
//                           color: const Color(0xFFDCA1A7).withOpacity(0.3),
//                           blurRadius: 20,
//                           spreadRadius: 2,
//                         ),
//                       ],
//                     ),
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         // Image du vainqueur
//                         Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: winnerIsBot
//                               ? Image.asset(
//                                   winnerData['outfitData']?['imageUrl'] ??
//                                       'assets/bots/poupee_chic.png',
//                                   fit: BoxFit.contain,
//                                 )
//                               : const Center(
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(
//                                         Icons.stars,
//                                         size: 60,
//                                         color: Colors.amber,
//                                       ),
//                                       SizedBox(height: 8),
//                                       Text(
//                                         "Styliste Humain !",
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.grey,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                         ),

//                         // Badge couronne en haut à droite
//                         const Positioned(
//                           top: 12,
//                           right: 12,
//                           child: CircleAvatar(
//                             backgroundColor: Colors.amber,
//                             radius: 20,
//                             child: Icon(
//                               Icons.emoji_events,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),

//                         // Nom et score en bas
//                         Positioned(
//                           bottom: 0,
//                           left: 0,
//                           right: 0,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF704E52).withOpacity(0.85),
//                               borderRadius: const BorderRadius.only(
//                                 bottomLeft: Radius.circular(24),
//                                 bottomRight: Radius.circular(24),
//                               ),
//                             ),
//                             padding: const EdgeInsets.symmetric(vertical: 8),
//                             child: Text(
//                               winnerIsBot
//                                   ? "Modèle Virtuel ($winnerVotes ⭐)"
//                                   : "Vous / Styliste Réel ($winnerVotes ⭐)",
//                               textAlign: TextAlign.center,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // 📊 LE CLASSEMENT DU RESTE DES JOUEURS
//                 Expanded(
//                   flex: 4,
//                   child: ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     itemCount: podiumList.length,
//                     itemBuilder: (context, index) {
//                       var data =
//                           podiumList[index].data() as Map<String, dynamic>;
//                       bool isBot = data['isBot'] ?? false;
//                       int votes = data['votesCount'] ?? 0;

//                       // Petites icônes pour le podium
//                       String rankPrefix = "${index + 1}. ";
//                       if (index == 0) rankPrefix = "🥇 ";
//                       if (index == 1) rankPrefix = "🥈 ";
//                       if (index == 2) rankPrefix = "🥉 ";

//                       return Card(
//                         margin: const EdgeInsets.symmetric(vertical: 4),
//                         color: index == 0
//                             ? const Color(0xFFFFF9E6)
//                             : Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: ListTile(
//                           leading: Text(
//                             rankPrefix,
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           title: Text(
//                             isBot ? "Modèle Virtuel" : "Joueur Réel",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: index == 0
//                                   ? Colors.amber[800]
//                                   : const Color(0xFF704E52),
//                             ),
//                           ),
//                           trailing: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFDCA1A7).withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Text(
//                               "$votes ⭐",
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: Color(0xFF704E52),
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),

//                 // ↩️ BOUTON QUITTER / RETOUR AU MENU
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF704E52),
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(200, 45),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                     ),
//                     onPressed: () => context.go('/'), // Retour à l'accueil
//                     icon: const Icon(Icons.home),
//                     label: const Text(
//                       "Retour à l'Accueil",
//                       style: TextStyle(fontWeight: FontWeight.bold),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultZoneScreen extends StatelessWidget {
  final String roomId;

  const ResultZoneScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5), // Même fond doux
      appBar: AppBar(
        title: const Text(
          "🏆 RÉSULTATS DU DÉFILÉ 🏆",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFDCA1A7),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // On récupère les tenues triées par le plus grand nombre de votes d'abord !
        stream: FirebaseFirestore.instance
            .collection('lobbies')
            .doc(roomId)
            .collection('submitted_outfits')
            .orderBy('votesCount', descending: true)
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
                "Calcul des scores finaux...",
                style: TextStyle(color: Color(0xFF704E52), fontSize: 16),
              ),
            );
          }

          final podiumList = snapshot.data!.docs;

          // On récupère les infos du grand gagnant (Le premier de la liste)
          var winnerData = podiumList[0].data() as Map<String, dynamic>;
          bool winnerIsBot = winnerData['isBot'] ?? false;
          int winnerVotes = winnerData['votesCount'] ?? 0;

          // 👑 AJOUTÉ : Récupération du vrai pseudo pour le vainqueur
          String winnerName =
              winnerData['username'] ??
              (winnerIsBot ? "Modèle Virtuel" : "Styliste Réel");

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 15),

                // 🎉 TEXTE D'ANIMATION DU VAINQUEUR
                const Text(
                  "✨ ET LA GAGNANTE EST ✨",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF704E52),
                    letterSpacing: 2,
                  ),
                ),

                // 👑 AFFICHAGE EN GRAND DE LA POUPÉE GAGNANTE
                Expanded(
                  flex: 5,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDCA1A7).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Image du vainqueur
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: winnerIsBot
                              ? Image.asset(
                                  winnerData['outfitData']?['imageUrl'] ??
                                      'assets/bots/poupee_chic.png',
                                  fit: BoxFit.contain,
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.stars,
                                        size: 60,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Incroyable Look !",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),

                        // Badge couronne en haut à droite
                        const Positioned(
                          top: 12,
                          right: 12,
                          child: CircleAvatar(
                            backgroundColor: Colors.amber,
                            radius: 20,
                            child: Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Nom et score en bas
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF704E52).withValues(alpha: 0.85),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              // 👈 MODIFIÉ : Affiche désormais le vrai nom sur la bannière du gagnant
                              "$winnerName ($winnerVotes ⭐)",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 📊 LE CLASSEMENT DU RESTE DES JOUEURS
                Expanded(
                  flex: 4,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: podiumList.length,
                    itemBuilder: (context, index) {
                      var data =
                          podiumList[index].data() as Map<String, dynamic>;
                      bool isBot = data['isBot'] ?? false;
                      int votes = data['votesCount'] ?? 0;

                      // 👈 AJOUTÉ : Récupération du vrai pseudo pour la ligne du classement
                      String displayName =
                          data['username'] ??
                          (isBot ? "Modèle Virtuel" : "Joueur Réel");

                      // Petites icônes pour le podium
                      String rankPrefix = "${index + 1}. ";
                      if (index == 0) rankPrefix = "🥇 ";
                      if (index == 1) rankPrefix = "🥈 ";
                      if (index == 2) rankPrefix = "🥉 ";

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: index == 0
                            ? const Color(0xFFFFF9E6)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Text(
                            rankPrefix,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          title: Text(
                            // 👈 MODIFIÉ : Affiche le vrai pseudo à la place des labels génériques
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index == 0
                                  ? Colors.amber[800]
                                  : const Color(0xFF704E52),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCA1A7).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "$votes ⭐",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF704E52),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ↩️ BOUTON QUITTER / RETOUR AU MENU
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF704E52),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () => context.go('/room'), // Retour à l'accueil
                    icon: const Icon(Icons.home),
                    label: const Text(
                      "Retour à l'Accueil",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
