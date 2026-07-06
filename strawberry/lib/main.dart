import 'package:flutter/material.dart';
import 'package:strawberry/features/splash/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strawberry',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}

