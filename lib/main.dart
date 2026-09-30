import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const FutbolBaseApp());
}

class FutbolBaseApp extends StatelessWidget {
  const FutbolBaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FutbolBAse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A66C2)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomeScreen(),
    );
  }
}
