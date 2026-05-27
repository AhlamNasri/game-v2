// import 'package:fashion_room_girls/presentation/auth/first_screen.dart';
// import 'package:fashion_room_girls/presentation/auth/login_screen.dart';
// import 'package:fashion_room_girls/presentation/auth/register_screen.dart';
// import 'package:fashion_room_girls/presentation/competition/competition_intro_screen.dart';
// import 'package:fashion_room_girls/presentation/competition/competition_screen.dart';
// import 'package:fashion_room_girls/presentation/competition/LobbyScreen.dart';
// import 'package:fashion_room_girls/presentation/competition/play_zone_screen.dart';
// import 'package:fashion_room_girls/presentation/competition/test.dart';
// import 'package:fashion_room_girls/presentation/competition/voting_zone_screen.dart';
// import 'package:go_router/go_router.dart';
// import 'presentation/room_design/room_screen.dart';

// final appRouter = GoRouter(
//   initialLocation: '/first', // opens room directly for now
//   routes: [
//     GoRoute(
//       path: '/',
//       // ra exemple hta n9ado scren d'aceuille htit login hna
//       builder: (context, state) => const LoginScreen(),
//     ),
//     GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
//     GoRoute(
//       path: '/register',
//       builder: (context, state) => const RegisterScreen(),
//     ),
//     GoRoute(path: '/room', builder: (context, state) => const RoomScreen()),

//     GoRoute(
//       path: '/lobby',
//       builder: (context, state) {
//         // 1. On récupère le paramètre 'roomId' depuis l'URL
//         // Si pour une raison ou une autre il est absent, on met une valeur vide '' par sécurité
//         final roomId = state.uri.queryParameters['roomId'] ?? '';

//         // 2. On passe cet ID en paramètre à ton écran LobbyScreen
//         return LobbyScreen(lobbyId: roomId);
//       },
//     ),
//     GoRoute(path: '/test', builder: (context, state) => Test()),

//     GoRoute(
//       path: '/competition',
//       builder: (context, state) {
//         final roomId = state.uri.queryParameters['roomId'] ?? '';
//         return CompetitionIntroScreen(roomId: roomId);
//       },
//     ),

//     // 2. Le vrai terrain de jeu (Où l'écran d'intro t'envoie après les 5s)
//     GoRoute(
//       path: '/play-zone',
//       builder: (context, state) {
//         final roomId = state.uri.queryParameters['roomId'] ?? '';
//         return PlayZoneScreen(roomId: roomId); // Ton écran de création final
//       },
//     ),
//     GoRoute(
//       path: '/voting-zone',
//       builder: (context, state) {
//         final roomId = state.uri.queryParameters['roomId'] ?? '';
//         return VotingZoneScreen(roomId: roomId);
//       },
//     ),
//     GoRoute(path: '/first', builder: (context, state) => FirstScreen()),
//   ],
// );

import 'package:fashion_room_girls/presentation/auth/first_screen.dart';
import 'package:fashion_room_girls/presentation/auth/login_screen.dart';
import 'package:fashion_room_girls/presentation/auth/register_screen.dart';
<<<<<<< HEAD
import 'package:fashion_room_girls/presentation/competition/competition_intro_screen.dart';
import 'package:fashion_room_girls/presentation/competition/LobbyScreen.dart';
import 'package:fashion_room_girls/presentation/competition/play_zone_screen.dart';
import 'package:fashion_room_girls/presentation/competition/result_zone_screen.dart';
import 'package:fashion_room_girls/presentation/competition/test.dart';
import 'package:fashion_room_girls/presentation/competition/voting_zone_screen.dart';
=======
import 'package:fashion_room_girls/presentation/competition/competition_screen.dart';
import 'package:fashion_room_girls/presentation/dress_up/dress_up_screen.dart';
import 'package:fashion_room_girls/presentation/menu/menu_screen.dart';
import 'package:fashion_room_girls/presentation/shop/shop_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
>>>>>>> upstream/develop
import 'package:go_router/go_router.dart';

import 'presentation/room_design/room_screen.dart';

<<<<<<< HEAD
// 🟢 On transforme la variable en une fonction qui accepte la route initiale calculée au démarrage
GoRouter createAppRouter(String initialRoute) {
  return GoRouter(
    initialLocation:
        initialRoute, // 👈 C'est ici qu'on applique la route dynamique !
    routes: [
      // C'est ici que l'enfant arrivera directement (sa chambre) s'il a déjà un compte enregistré !
      GoRoute(path: '/room', builder: (context, state) => const RoomScreen()),

      GoRoute(
        path: '/lobby',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId'] ?? '';
          return LobbyScreen(lobbyId: roomId);
        },
      ),
      GoRoute(path: '/test', builder: (context, state) => Test()),

      GoRoute(
        path: '/competition',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId'] ?? '';
          return CompetitionIntroScreen(roomId: roomId);
        },
      ),

      GoRoute(
        path: '/play-zone',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId'] ?? '';
          return PlayZoneScreen(roomId: roomId);
        },
      ),
      // GoRoute(
      //   path: '/voting-zone',
      //   builder: (context, state) {
      //     final roomId = state.uri.queryParameters['roomId'] ?? '';
      //     return VotingZoneScreen(roomId: roomId);
      //   },
      // ),
      GoRoute(path: '/first', builder: (context, state) => FirstScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId'] ?? '';
          return LoginScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId'] ?? '';
          return RegisterScreen(roomId: roomId);
        },
      ),

      GoRoute(
        path: '/voting-zone',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId'] ?? '';
          // On passe ici l'id de la joueuse connectée (ex: récupéré depuis ton auth)
          return VotingZoneScreen(
            roomId: roomId,
            currentUserId: 'uid_fadma_123',
          );
        },
      ),
      GoRoute(
        path: '/result-zone',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId'] ?? '';
          return ResultZoneScreen(roomId: roomId);
        },
      ),
    ],
  );
}
=======
final appRouter = GoRouter(
  initialLocation: '/menu',
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final onAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/';

    if (!loggedIn && !onAuthRoute) return '/login';
    if (loggedIn && onAuthRoute) return '/menu';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/menu', builder: (context, state) => const MenuScreen()),
    GoRoute(path: '/room', builder: (context, state) => const RoomScreen()),
    GoRoute(path: '/shop', builder: (context, state) => const ShopScreen()),
    GoRoute(
      path: '/dress-up',
      builder: (context, state) => const DressUpScreen(),
    ),
    GoRoute(
      path: '/lobby',
      builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId'] ?? '';
        return CompetitionScreen(roomId: roomId);
      },
    ),
  ],
);
>>>>>>> upstream/develop
