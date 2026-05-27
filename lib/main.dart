import 'package:fashion_room_girls/data/services/user_service.dart';
import 'package:fashion_room_girls/presentation/room_design/theme/room_ui.dart';
import 'package:fashion_room_girls/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  UserService userService = UserService();
  Map<String, String?> localUser = await userService.getLocalUser();

  // 2. Par défaut, s'il n'a pas de profil, on l'envoie sur le RegisterScreen (pour choisir pseudo/avatar)
  String targetRoute = '/first';

  if (localUser['uid'] != null) {
    // L'enfant a déjà créé sa poupée ! On l'envoie directement dans sa Chambre (RoomScreen)
    print("Bienvenue de retour, joueur : ${localUser['nickname']}");
    targetRoute = '/menu';
  }
  runApp(ProviderScope(child: MyApp(initialRoute: targetRoute)));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final router = createAppRouter(initialRoute);
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
      routerConfig: router,
    );
  }
}
