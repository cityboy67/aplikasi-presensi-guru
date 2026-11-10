import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'guru_dashboard_screen.dart';

class GantiPasswordGuruScreen extends StatefulWidget {
  const GantiPasswordGuruScreen({super.key});

  @override
  State<GantiPasswordGuruScreen> createState() =>
      _GantiPasswordGuruScreenState();
}

class _GantiPasswordGuruScreenState
    extends State<GantiPasswordGuruScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordBaruController = TextEditingController();
  final _konfirmasiController = TextEditingController();
  final _passwordLamaController = TextEditingController();

  final supabase = Supabase.instance.client;

  bool _passwordBaruObscured = true;
  bool _konfirmasiObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  Future<void> _simpanPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      final passwordLama = _passwordLamaController.text;
      final passwordBaru = _passwordBaruController.text;

      if (passwordLama == passwordBaru) {
        throw Exception(
          'Password baru tidak boleh sama dengan password lama.',
        );
      }

      // 1. Mengubah password pada Supabase Auth
      await supabase.auth.updateUser(
        UserAttributes(
          password: _passwordBaruController.text,
        ),
      );

      // 2. Mengubah status wajib ganti password
      await supabase
          .from('guru')
          .update({'wajib_ganti_password': false})
          .eq('user_id', user.id);

      // 3. Memastikan perubahan berhasil
      final guru = await supabase
          .from('guru')
          .select('wajib_ganti_password')
          .eq('user_id', user.id)
          .maybeSingle();

      if (guru == null || guru['wajib_ganti_password'] != false) {
        throw Exception('Status perubahan password belum berhasil disimpan.');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diperbarui.'),
          backgroundColor: Color(0xFF194432),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const GuruDashboardScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.grey.shade500,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF41735E),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;

            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: screenHeight * 0.35,
                  child: Image.asset(
                    'assets/images/bg_alaqsha.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1B4D4F),
                    ),
                  ),
                ),
                Positioned.fill(
                  top: screenHeight * 0.28,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(
                              child: Text(
                                'Buat Password Baru',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Demi keamanan akun, silakan ganti password awal '
                              'sebelum melanjutkan ke dashboard.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),

                            const Text(
                              'Password Lama',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordLamaController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Masukkan password awal',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password lama wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            const Text(
                              'Password Baru',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordBaruController,
                              obscureText: _passwordBaruObscured,
                              decoration: _inputDecoration(
                                hint: 'Masukkan password baru',
                                obscure: _passwordBaruObscured,
                                onToggle: () {
                                  setState(() {
                                    _passwordBaruObscured =
                                        !_passwordBaruObscured;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password baru wajib diisi';
                                }
                                if (value.length < 8) {
                                  return 'Password minimal 8 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            const Text(
                              'Konfirmasi Password Baru',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _konfirmasiController,
                              obscureText: _konfirmasiObscured,
                              decoration: _inputDecoration(
                                hint: 'Ulangi password baru',
                                obscure: _konfirmasiObscured,
                                onToggle: () {
                                  setState(() {
                                    _konfirmasiObscured =
                                        !_konfirmasiObscured;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Konfirmasi password wajib diisi';
                                }
                                if (value != _passwordBaruController.text) {
                                  return 'Konfirmasi password tidak sama';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Gunakan minimal 8 karakter untuk password baru.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 28),

                            ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _simpanPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF41735E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan Password',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 24),
                            _buildCollaborationSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollaborationSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogoCircle(
          'assets/images/logo_upi.png',
          Icons.school_rounded,
          Colors.red,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'X',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildLogoCircle(
          'assets/images/logo_mitra.png',
          Icons.public_rounded,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildLogoCircle(
    String imagePath,
    IconData fallbackIcon,
    Color fallbackColor,
  ) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              fallbackIcon,
              color: fallbackColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}