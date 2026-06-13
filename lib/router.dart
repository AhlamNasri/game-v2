import 'package:fashion_room_girls/presentation/auth/first_screen.dart';
import 'package:fashion_room_girls/presentation/auth/login_screen.dart';
import 'package:fashion_room_girls/presentation/auth/register_screen.dart';
import 'package:fashion_room_girls/presentation/character_selection/character_selection_screen.dart';
import 'package:fashion_room_girls/presentation/competition/competition_intro_screen.dart';
import 'package:fashion_room_girls/presentation/competition/lobby_screen.dart';
import 'package:fashion_room_girls/presentation/competition/play_zone_screen.dart';
import 'package:fashion_room_girls/presentation/competition/result_zone_screen.dart';
import 'package:fashion_room_girls/presentation/competition/join_competition_button.dart';
import 'package:fashion_room_girls/presentation/competition/voting_zone_screen.dart';
import 'package:fashion_room_girls/presentation/character_selection/character_selection_screen.dart';
import 'package:fashion_room_girls/presentation/dressing/dressing_screen.dart';
import 'package:fashion_room_girls/presentation/leaderboard/leaderboard_screen.dart';
import 'package:fashion_room_girls/presentation/menu/menu_screen.dart';
import 'package:fashion_room_girls/presentation/shop/shop_screen.dart';
import 'package:fashion_room_girls/presentation/settings/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/room_design/room_screen.dart';

GoRouter createAppRouter(String initialRoute) {
  return GoRouter(
    initialLocation: initialRoute,
    redirect: (context, state) async {
      if (state.uri.path == '/menu') {
        final prefs = await SharedPreferences.getInstance();
        final uid = prefs.getString('user_uid');
        if (uid == null) return '/first';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => FirstScreen()),
      GoRoute(path: '/room', builder: (context, state) => const RoomScreen()),
      GoRoute(
        path: '/lobby',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId'] ?? '';
          return LobbyScreen(lobbyId: roomId);
        },
      ),
      GoRoute(path: '/test', builder: (context, state) => JoinCompetitionButton()),
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
          final currentUserId =
              FirebaseAuth.instance.currentUser?.uid ?? '';
          return PlayZoneScreen(roomId: roomId, currentUserId: currentUserId);
        },
      ),
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
          final currentUserId =
              state.uri.queryParameters['currentUserId'] ??
              FirebaseAuth.instance.currentUser?.uid ??
              '';
          return VotingZoneScreen(
            roomId: roomId,
            currentUserId: currentUserId,
          );
        },
      ),
      GoRoute(
        path: '/result-zone',
        builder: (context, state) {
          final roomId = state.uri.queryParameters['roomId'] ?? '';
          final currentUserId =
              state.uri.queryParameters['currentUserId'] ??
              FirebaseAuth.instance.currentUser?.uid ??
              '';
          return ResultZoneScreen(
              roomId: roomId, currentUserId: currentUserId);
        },
      ),
      GoRoute(path: '/menu', builder: (context, state) => const MenuScreen()),
      GoRoute(path: '/shop', builder: (context, state) => const ShopScreen()),
      GoRoute(
        path: '/character',
        builder: (context, state) => const CharacterSelectionScreen(),
      ),
      GoRoute(
        path: '/dressing',
        builder: (context, state) => const DressingScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/dress-up',
        builder: (context, state) => const CharacterSelectionScreen(),
      ),
    ],
  );
}
