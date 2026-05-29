// // import 'package:fashion_room_girls/data/services/LobbyService.dart';
// // import 'package:firebase_auth/firebase_auth.dart'; // 👈 1. NE PAS OUBLIER CET IMPORT
// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';

// // class Test extends StatelessWidget {
// //   const Test({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return ElevatedButton(
// //       onPressed: () async {
// //         // 1. Afficher un indicateur de chargement visuel
// //         showDialog(
// //           context: context,
// //           barrierDismissible: false,
// //           builder: (context) =>
// //               const Center(child: CircularProgressIndicator()),
// //         );

// //         try {
// //           // 2. On récupère les infos nécessaires
// //           String myUid = "uid_fadma_123";
// //           int myLevel = 1;

// //           // 3. Appel du service de matchmaking
// //           String roomId = await LobbyService().findOrCreateLobby(
// //             currentUserId: myUid,
// //             userLevel: myLevel,
// //           );

// //           // 4. On ferme le dialogue de chargement
// //           if (context.mounted) Navigator.pop(context);

// //           // 🔥 5. LA VÉRIFICATION MAGIQUE ICI 🔥
// //           final User? currentUser = FirebaseAuth.instance.currentUser;

// //           if (currentUser != null && currentUser.isAnonymous) {
// //             // CAS A : C'est un invité (anonyme) -> On l'envoie s'enregistrer avec le roomId
// //             print("Utilisateur Anonyme -> Direction Inscription/Login");
// //             if (context.mounted) {
// //               context.push('/login?roomId=$roomId');
// //             }
// //           } else {
// //             // CAS B : Il a déjà un vrai compte (ou connecté) -> Direction le Lobby direct !
// //             print("Utilisateur Officiel -> Direction le Lobby directement");
// //             if (context.mounted) {
// //               context.push('/lobby?roomId=$roomId');
// //             }
// //           }
// //         } catch (error) {
// //           if (context.mounted) Navigator.pop(context); // Fermer le chargement
// //           if (context.mounted) {
// //             ScaffoldMessenger.of(context).showSnackBar(
// //               SnackBar(
// //                 content: Text("Impossible de trouver une salle : $error"),
// //               ),
// //             );
// //           }
// //         }
// //       },
// //       child: const Text("Rejoindre la Compétition"),
// //     );
// //   }
// // }

// import 'package:fashion_room_girls/data/services/lobbyService.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// // Utile si tu récupères les données en ligne
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class Test extends StatelessWidget {
//   const Test({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: () async {
//         // 1. Afficher un indicateur de chargement visuel
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) =>
//               const Center(child: CircularProgressIndicator()),
//         );

//         try {
//           // 2. On récupère les infos locales ou par défaut depuis SharedPreferences
//           final SharedPreferences prefs = await SharedPreferences.getInstance();

//           // Récupération de l'ID utilisateur (Firebase Auth ou SharedPreferences)
//           final User? currentUser = FirebaseAuth.instance.currentUser;
//           String myUid =
//               currentUser?.uid ?? prefs.getString('uid') ?? "uid_inconnu";

//           // Récupération du pseudo et de l'avatar sauvegardés localement
//           String myNickname = prefs.getString('user_nickname') ?? "Joueur";
//           String myAvatarId =
//               prefs.getString('user_avatarId') ?? "default_avatar";
//           int myLevel =
//               prefs.getInt('user_level') ??
//               1; // Niveau dynamique (ou laisse 1 par défaut)

//           // 🚨 Si l'utilisateur n'est pas connecté du tout sur Firebase, on le redirige vers le login d'abord
//           if (currentUser == null) {
//             if (context.mounted) Navigator.pop(context); // Ferme le loader
//             if (context.mounted) context.push('/login?roomId=none');
//             return;
//           }

//           // 3. Appel du service de matchmaking avec la nouvelle structure complète 📦
//           String roomId = await LobbyService().findOrCreateLobby(
//             currentUserId: myUid,
//             currentUserNickname: myNickname,
//             currentUserAvatarId: myAvatarId,
//             userLevel: myLevel,
//           );

//           // 4. On ferme le dialogue de chargement
//           if (context.mounted) Navigator.pop(context);

//           // 5. Direction le Lobby direct ! 🚀
//           print("Profil complet injecté -> Direction le Lobby : $roomId");
//           if (context.mounted) {
//             // Note : Utilise widget.lobbyId dans ton LobbyScreen pour lire la variable roomId passée ici
//             context.push('/lobby?roomId=$roomId');
//           }
//         } catch (error) {
//           // Fermer le chargement en cas de crash
//           if (context.mounted) Navigator.pop(context);
//           if (context.mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text("Impossible de trouver une salle : $error"),
//               ),
//             );
//           }
//         }
//       },
//       child: const Text("Rejoindre la Compétition"),
//     );
//   }
// }

import 'package:fashion_room_girls/data/services/lobbyService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Test extends StatelessWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // 1. Récupération immédiate de l'utilisateur Firebase actuel
        final User? currentUser = FirebaseAuth.instance.currentUser;

        // 🚨 VÉRIF MAGIQUE : Si pas connecté OU si le compte est anonyme (Guest)
        // On le redirige direct vers le login avant même d'ouvrir le loader
        if (currentUser == null || currentUser.isAnonymous) {
          print(
            "Accès refusé : Utilisateur déconnecté ou Anonyme -> Redirection Login",
          );
          if (context.mounted) {
            context.push('/login?roomId=none');
          }
          return; // On stoppe l'exécution ici !
        }

        // 2. Si on arrive ici, l'utilisateur a un VRAI compte officiel.
        // On peut afficher l'indicateur de chargement visuel pour le matchmaking.
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          // 3. On récupère les infos locales ou par défaut depuis SharedPreferences
          final SharedPreferences prefs = await SharedPreferences.getInstance();

          // On utilise directement l'uid de Firebase puisqu'on est sûr qu'il est connecté
          String myUid = currentUser.uid;

          // Récupération du pseudo, de l'avatar et du niveau sauvegardés localement
          String myNickname = prefs.getString('user_nickname') ?? "Joueur";
          String myAvatarId =
              prefs.getString('user_avatarId') ?? "default_avatar";
          int myLevel = prefs.getInt('user_level') ?? 1;

          // 4. Appel du service de matchmaking avec la structure complète 📦
          String roomId = await LobbyService().findOrCreateLobby(
            currentUserId: myUid,
            currentUserNickname: myNickname,
            currentUserAvatarId: myAvatarId,
            userLevel: myLevel,
          );

          // 5. On ferme le dialogue de chargement dès que la salle est trouvée/créée
          if (context.mounted) {
            Navigator.pop(context);
          }

          // 6. Direction le Lobby en direct ! 🚀
          print("Profil officiel injecté -> Direction le Lobby : $roomId");
          if (context.mounted) {
            context.push('/lobby?roomId=$roomId');
          }
        } catch (error) {
          // Fermer le chargement en cas de crash ou problème réseau
          if (context.mounted) {
            Navigator.pop(context);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Impossible de trouver une salle : $error"),
              ),
            );
          }
        }
      },
      child: const Text("Rejoindre la Compétition"),
    );
  }
}
