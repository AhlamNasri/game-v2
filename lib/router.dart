import 'package:fashion_room_girls/presentation/auth/login_screen.dart';
import 'package:fashion_room_girls/presentation/auth/register_screen.dart';
import 'package:go_router/go_router.dart';

// final appRouter = GoRouter(
//   routes: [
//     GoRoute(
//       path: '/',
//       builder: (context, state) => const Scaffold(
//         body: Center(
//           child: Text('Fashion Room Girls'),
//         ),
//       ),
//     ),
//   ],
// );

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
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
  ],
);
