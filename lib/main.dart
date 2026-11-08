import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/splash_screen.dart';

Future<void> main() async {
  // Memastikan Flutter siap sebelum inisialisasi
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://llqkmwaimudwkspypbfj.supabase.co/rest/v1/',
    publishableKey: 'sb_publishable_2VIE0KA7VfMqJFjZOyUnPw_4R8or2hu',
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
      title: 'Presensi Guru Al Aqsha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.teal,
        useMaterial3: false,
      ),
      home: const SplashScreen(),
    );
  }
}