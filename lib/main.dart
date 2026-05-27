import 'package:fashion_room_girls/data/services/user_service.dart';
import 'package:fashion_room_girls/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    final router = createAppRouter(initialRoute);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
