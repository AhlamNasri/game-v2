import 'package:fashion_room_girls/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. On injecte tes clés Web manuellement pour tes tests
  // await Firebase.initializeApp(
  //   options: const FirebaseOptions(
  //     apiKey: "AIzaSyA48hqd7mb2bNLqnFpsBHe0ZvAEslSniUs",
  //     authDomain: "test-poupee-fashion-game.firebaseapp.com",
  //     projectId: "test-poupee-fashion-game",
  //     storageBucket: "test-poupee-fashion-game.firebasestorage.app",
  //     messagingSenderId: "446347040413",
  //     appId: "1:446347040413:web:94ea952f4fe780f131e674",
  //     measurementId: "G-YQ6ZNZM1KN",
  //   ),
  // );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fashion Room Girls',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),

      routerConfig: appRouter,
    );
  }
}