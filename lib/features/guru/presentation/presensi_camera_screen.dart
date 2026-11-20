
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PresensiCameraScreen extends StatefulWidget {
  const PresensiCameraScreen({super.key});

  @override
  State<PresensiCameraScreen> createState() =>
      _PresensiCameraScreenState();
}

class _PresensiCameraScreenState
    extends State<PresensiCameraScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _foto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ambilFoto();
  }

  Future<void> _ambilFoto() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final XFile? hasil = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 1280,
      );

      if (!mounted) return;

      if (hasil == null) {
        Navigator.pop(context);
        return;
      }

      setState(() {
        _foto = File(hasil.path);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka kamera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _gunakanFoto() {
    if (_foto == null) return;

    Navigator.pop(context, _foto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Foto Bukti Presensi'),
        backgroundColor: const Color(0xFF194432),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : _foto != null
                        ? Image.file(
                            _foto!,
                            fit: BoxFit.contain,
                          )
                        : const Text(
                            'Belum ada foto',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
              ),
            ),

            if (_foto != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _ambilFoto,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Ambil Ulang'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _gunakanFoto,
                        icon: const Icon(Icons.check),
                        label: const Text('Gunakan Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF52C488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}