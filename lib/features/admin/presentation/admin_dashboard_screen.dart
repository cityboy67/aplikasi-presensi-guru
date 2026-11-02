import 'package:flutter/material.dart';
import 'detail_presensi_admin_screen.dart';
import 'rekap_presensi_screen.dart';
import 'tambah_guru_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedNav = 0;

  // Dummy data guru
  List<Map<String, dynamic>> teachers = List.generate(
    4,
    (index) => {
      "name": "Muhammad Budi",
      "nip": "19850412 201001 1 015",
      "subject": "Teknik Jaringan",
      "status": "AKTIF",
      "image": "assets/images/foto_guru.jpg",
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      bottomNavigationBar: _buildBottomNavigation(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_selectedNav) {
      case 1:
        return const DetailPresensiAdminScreen();
      case 2:
        return const RekapPresensiScreen();
      default:
        return _buildDashboardContent(context);
    }
  }

  // ── Dashboard utama (Data Guru) ──────────────────────────────
  Widget _buildDashboardContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildSearchBar(),
          const SizedBox(height: 38),
          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: teachers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (_, index) =>
                _buildTeacherCard(teachers[index], index),
          ),
          const SizedBox(height: 48),
          _buildAddTeacherButton(context),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // ── 1. HEADER BAR ────────────────────────────────────────────
  Widget _buildHeader() {
    const titles = ['Kelola Data Guru', 'Detail Presensi', 'Rekap Presensi'];
    return Container(
      height: 56,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF00CE36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.menu, color: Colors.white, size: 22),
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              Text(
                titles[_selectedNav],
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo_upi.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '×',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo_mitra.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. SEARCH BAR ────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFD9DDE3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: Color(0xFF9299A2)),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF263347),
              ),
              decoration: InputDecoration(
                hintText: 'Cari nama, NIP, atau mata pelajaran...',
                hintStyle: TextStyle(color: Color(0xFF9299A2), fontSize: 11),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.tune, size: 15, color: Color(0xFF9299A2)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── 3. CARD DATA GURU ────────────────────────────────────────
  Widget _buildTeacherCard(Map<String, dynamic> data, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(30, 50, 80, 0.08),
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              height: 3,
              width: double.infinity,
              color: const Color(0xFF00CE70),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto Profil + green dot
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              data['image'] as String,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4B8068,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF4B8068),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D477),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Info guru
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] as String,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263347),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.badge_outlined,
                                  size: 10,
                                  color: Color(0xFF8993A1),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'NIP: ${data['nip']}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    color: Color(0xFF8993A1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.lan_outlined,
                                  size: 10,
                                  color: Color(0xFF21B6ED),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  data['subject'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF263347),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Badge status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6FAEF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFD2F4E1)),
                        ),
                        child: Text(
                          '• ${data['status']}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF20B76E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    height: 1,
                    color: const Color(0xFFE9EDF2),
                  ),
                  // Tombol Hapus & Detail
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Hapus Guru'),
                              content: Text(
                                'Apakah Anda yakin ingin menghapus data ${data['name']}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      teachers.removeAt(index);
                                    });
                                    Navigator.pop(dialogContext);
                                  },
                                  child: const Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 11,
                                color: Color(0xFFF0525D),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Hapus',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFF0525D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _selectedNav = 1),
                        child: Container(
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            border: Border.all(color: const Color(0xFFE7ECF2)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Detail',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF263347),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                size: 12,
                                color: Color(0xFF263347),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. TOMBOL TAMBAH DATA GURU ───────────────────────────────
  Widget _buildAddTeacherButton(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF4B8068),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(50, 80, 60, 0.20),
            offset: Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TambahGuruScreen()),
            );
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                '+ Tambah Data Guru Baru',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 5. BOTTOM NAVIGATION BAR ─────────────────────────────────
  Widget _buildBottomNavigation(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 80 + bottomPad,
      width: double.infinity,
      color: const Color.fromARGB(255, 48, 145, 74),
      alignment: Alignment.center,
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.88,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF164F2B),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItemImage(
              index: 0,
              label: 'Data Guru',
              imagePath: 'assets/images/nav-dashboard.png',
              iconSize: 34, // ← besarkan icon Data Guru
            ),
            _navItemImage(
              index: 1,
              label: 'Presensi',
              imagePath: 'assets/images/nav-detail-presensi.png',
            ),
            _navItemImage(
              index: 2,
              label: 'Rekap',
              imagePath: 'assets/images/nav-rekap-presensi.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItemImage({
    required int index,
    required String label,
    required String imagePath,
    double iconSize = 26, // ← ubah angka di sini untuk setiap icon
  }) {
    final isActive = _selectedNav == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNav = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: isActive ? 14 : 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6ADD8B) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              width: iconSize,
              height: iconSize,
              color: isActive ? const Color(0xFF174E2B) : Colors.white70,
              errorBuilder: (_, __, ___) => Icon(
                Icons.bar_chart_rounded,
                color: isActive ? const Color(0xFF174E2B) : Colors.white70,
                size: iconSize,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF174E2B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
