import 'package:fashion_room_girls/data/services/soundtrack_service.dart';
import 'package:fashion_room_girls/data/services/user_service.dart';
import 'package:fashion_room_girls/router.dart';
import 'package:fashion_room_girls/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SoundtrackService.instance.initialize();

  final userService = UserService();
  final localUser = await userService.getLocalUser();

  var targetRoute = '/first';

  if (localUser['uid'] != null) {
    debugPrint("Bienvenue de retour, joueur : ${localUser['nickname']}");
    targetRoute = '/menu';
  }
  runApp(ProviderScope(child: MyApp(initialRoute: '/dressing'))); // TEMP-VERIFY
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fashion Room Girls',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: createAppRouter(initialRoute),
    );
  }
}
