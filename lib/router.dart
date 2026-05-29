import 'package:fashion_room_girls/presentation/auth/login_screen.dart';
import 'package:fashion_room_girls/presentation/auth/register_screen.dart';
import 'package:go_router/go_router.dart';
import 'presentation/dressing/dressing_screen.dart';
import 'presentation/room_design/room_screen.dart';

final appRouter = GoRouter(
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
    GoRoute(
      path: '/dressing',
      builder: (context, state) => const DressingScreen(),
    ),
    GoRoute(
      path: '/dress-up',
      builder: (context, state) => const DressingScreen(),
    ),
  ],
);
