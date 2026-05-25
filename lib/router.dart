import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'presentation/room_design/room_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/room',  // opens room directly for now
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text('Fashion Room Girls'),
        ),
      ),
    ),
    GoRoute(
      path: '/room',
      builder: (context, state) => const RoomScreen(),
    ),
  ],
);