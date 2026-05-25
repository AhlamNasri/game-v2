import 'package:fashion_room_girls/presentation/auth/login_screen.dart';
import 'package:fashion_room_girls/presentation/auth/register_screen.dart';
import 'package:go_router/go_router.dart';
import 'presentation/room_design/room_screen.dart';
import 'presentation/shop/shop_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/room', // opens room directly for now
  initialLocation: '/room', // opens room directly for now
  routes: [
    GoRoute(
      path: '/',
      // ra exemple hta n9ado scren d'aceuille htit login hna
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/room', builder: (context, state) => const RoomScreen()),
  ],
);

