import 'package:flutter/material.dart';

// Halaman Ambil Foto / Scanning Wajah saat Presensi
class PresensiCameraScreen extends StatelessWidget {
  const PresensiCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Kamera Presensi / Face Recognition'),
      ),
    );
  }
}