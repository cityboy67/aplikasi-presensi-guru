import 'package:flutter/material.dart';

// Tampilan Pilih Role (Masuk Sebagai Admin atau Guru)
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Pilih Role: Admin / Guru'),
      ),
    );
  }
}