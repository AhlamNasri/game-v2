<<<<<<< HEAD
import 'package:fashion_room_girls/data/services/user_service.dart';
=======
import 'package:fashion_room_girls/presentation/room_design/theme/room_ui.dart';
>>>>>>> upstream/develop
import 'package:fashion_room_girls/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
<<<<<<< HEAD
=======
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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
>>>>>>> upstream/develop
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  UserService userService = UserService();
  Map<String, String?> localUser = await userService.getLocalUser();

  // 2. Par défaut, s'il n'a pas de profil, on l'envoie sur le RegisterScreen (pour choisir pseudo/avatar)
  String targetRoute = '/first';

  if (localUser['uid'] != null) {
    // L'enfant a déjà créé sa poupée ! On l'envoie directement dans sa Chambre (RoomScreen)
    print("Bienvenue de retour, joueur : ${localUser['nickname']}");
    targetRoute = '/test';
  }
  runApp(ProviderScope(child: MyApp(initialRoute: targetRoute)));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final router = createAppRouter(initialRoute);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
=======
    final colorScheme = ColorScheme.fromSeed(seedColor: RoomUi.accent).copyWith(
      primary: RoomUi.accent,
      secondary: RoomUi.pillText,
      surface: RoomUi.softPanel,
      onPrimary: Colors.white,
      onSurface: RoomUi.ink,
    );

    return MaterialApp.router(
      title: 'Fashion Room Girls',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFFFEEF7),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: RoomUi.accent,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF7E3565),
          contentTextStyle: TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: RoomUi.ink,
          displayColor: RoomUi.ink,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
>>>>>>> upstream/develop
    );
  }
}
