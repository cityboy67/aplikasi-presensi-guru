import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/splash_screen.dart';

Future<void> main() async {
  // Memastikan Flutter siap sebelum inisialisasi
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://pjugprryghwdhfiwhdin.supabase.co',
    publishableKey: 'sb_publishable_tHTfyOuuJixzvjFZ9MUOsQ_KbJ9bYs1',
  );

  runApp(const MyApp());
}

// Supabase client global
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Presensi Guru',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}