import 'package:flutter/material.dart';

import 'presentation/shop/shop_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Fashion Room Girls - Test Shop',
      debugShowCheckedModeBanner: false,
      home: ShopScreen(),
    );
  }
}
