/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'package:fashion_room_girls/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      //routerConfig: appRouter,
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'presentation/shop/shop_screen.dart';

void main() {
  // On lance directement ton écran sans passer par Firebase ou GoRouter pour tes tests
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fashion Room Girls - Test Shop',
      debugShowCheckedModeBanner: false,
      home: const ShopScreen(), // Ta boutique s'affiche immédiatement ici !
    );
  }
}