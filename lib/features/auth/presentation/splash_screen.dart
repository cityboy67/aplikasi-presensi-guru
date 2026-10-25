import 'package:flutter/material.dart';

// Tampilan Splash Screen (Logo Al-Aqsha dan Nama Aplikasi)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Splash Screen - AL AQSHA'),
      ),
    );
  }
}