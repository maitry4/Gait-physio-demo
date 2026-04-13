import 'package:flutter/material.dart';
import 'screens/screen1_connectivity.dart';

void main() {
  runApp(const GaitPhysioApp());
}

class GaitPhysioApp extends StatelessWidget {
  const GaitPhysioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gait Physio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF0F2F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4E6A),
          primary: const Color(0xFFFF4E6A),
          secondary: const Color(0xFF6C63FF),
        ),
        useMaterial3: true,
      ),
      home: const Screen1Connectivity(),
    );
  }
}