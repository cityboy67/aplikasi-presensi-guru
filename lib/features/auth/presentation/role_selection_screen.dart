import 'package:flutter/material.dart';
import 'login_admin_screen.dart';
import 'login_guru_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Header di Belakang Tulisan "AL AQSHA"
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.35,
            child: Stack(
              children: [
                // Gambar Gedung / Background Custom
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/bg_alaqsha.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF1B4D4F),
                      );
                    },
                  ),
                ),
                // Overlay Gelap Tipis agar Teks "AL AQSHA" Tetap Jelas
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.25),
                  ),
                ),
                // Teks "AL AQSHA" di Tengah Header
                const Center(
                  child: Text(
                    'AL AQSHA',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Container Putih Utama
          Positioned.fill(
            top: screenHeight * 0.28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
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
              child: Column(
                children: [
                  const Text(
                    'Masuk Sebagai',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Role Admin
                  _buildRoleCard(
                    context: context,
                    title: 'Admin',
                    icon: Icons.admin_panel_settings_rounded,
                    avatarBgColor: const Color(0xFF1E824C),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginAdminScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // Tombol Role Guru
                  _buildRoleCard(
                    context: context,
                    title: 'Guru',
                    icon: Icons.person_rounded,
                    avatarBgColor: const Color(0xFF1B6A42),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginGuruScreen(),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Section Logo Kolaborasi (Kiri x Kanan)
                  _buildCollaborationSection(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color avatarBgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF38C172),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x29000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: avatarBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF38C172),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Logo Kolaborasi
  Widget _buildCollaborationSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogoCircle(
          imagePath: 'assets/images/logo_upi.png',
          fallbackIcon: Icons.school_rounded,
          fallbackColor: Colors.red.shade700,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'X',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        _buildLogoCircle(
          imagePath: 'assets/images/logo_mitra.png',
          fallbackIcon: Icons.public_rounded,
          fallbackColor: Colors.teal.shade700,
        ),
      ],
    );
  }

  Widget _buildLogoCircle({
    required String imagePath,
    required IconData fallbackIcon,
    required Color fallbackColor,
  }) {
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
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                fallbackIcon,
                color: fallbackColor,
                size: 22,
              );
            },
          ),
        ),
      ),
    );
  }
}