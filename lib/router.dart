import 'package:fashion_room_girls/presentation/auth/login_screen.dart';
import 'package:fashion_room_girls/presentation/auth/register_screen.dart';
import 'package:fashion_room_girls/presentation/competition/competition_screen.dart';
import 'package:fashion_room_girls/presentation/dress_up/dress_up_screen.dart';
import 'package:fashion_room_girls/presentation/menu/menu_screen.dart';
import 'package:fashion_room_girls/presentation/shop/shop_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'presentation/room_design/room_screen.dart';

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