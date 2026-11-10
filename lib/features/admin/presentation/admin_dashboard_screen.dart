import 'package:flutter/material.dart';
import 'detail_guru_screen.dart';
import 'detail_presensi_admin_screen.dart';
import 'rekap_presensi_screen.dart';
import 'tambah_guru_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedNav = 0;

  // Dummy data guru
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> teachers = [];
  bool _isLoadingTeachers = true;
  String _searchQuery = '';

  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _loadTeachers() async {
    try {
      final response = await supabase
          .from('guru')
          .select(
            'guru_id, nama, niy, email, no_telepon, '
            'guru_jenis, status, foto_url, user_id',
          )
          .order('nama');

      final List<Map<String, dynamic>> loadedTeachers = [];

      for (final row in response) {
        final data = Map<String, dynamic>.from(row);

        String? imageUrl;
        final fotoPath = data['foto_url'] as String?;

        if (fotoPath != null && fotoPath.isNotEmpty) {
          try {
            imageUrl = await supabase.storage
                .from('foto-guru')
                .createSignedUrl(fotoPath, 3600);

            debugPrint('Path foto: $fotoPath');
            debugPrint('URL foto: $imageUrl');
          } catch (e) {
            debugPrint('Gagal mengambil foto: $e');
          }
        } else {
          debugPrint('Foto guru belum memiliki path.');
        }

        loadedTeachers.add({
          ...data,
          'name': data['nama'] ?? '-',
          'niy': data['niy']?.toString() ?? '-',
          'subject': data['guru_jenis'] ?? 'Wali Kelas',
          'status': data['status'] ?? 'Tidak diketahui',
          'imageUrl': imageUrl,
        });
      }

      if (!mounted) return;

      setState(() {
        teachers = loadedTeachers;
        _isLoadingTeachers = false;
      });
    } catch (e) {
      debugPrint('Gagal mengambil data guru: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingTeachers = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data guru: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // FUNGSI HAPUS GURU
  Future<void> _hapusGuru(String guruId) async {
    try {
      final response = await supabase.functions.invoke(
        'hapus-akun-guru',
        body: {
          'guru_id': guruId,
        },
      );

      final result = response.data;

      if (response.status != 200 ||
          result is! Map ||
          result['success'] != true) {
        throw Exception(
          result is Map
              ? result['message'] ?? 'Gagal menghapus guru.'
              : 'Gagal menghapus guru.',
        );
      }

      if (!mounted) return;

      await _loadTeachers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data guru berhasil dihapus.'),
          backgroundColor: Color(0xFF43816B),
        ),
      );

      if (result['foto_warning'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data berhasil dihapus, tetapi foto gagal dihapus: '
              '${result['foto_warning']}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus guru: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredTeachers {
    final query = _searchQuery.toLowerCase();

    return teachers.where((teacher) {
      final nama = (teacher['name'] ?? '').toString().toLowerCase();
      final niy = (teacher['niy'] ?? '').toString().toLowerCase();

      return nama.contains(query) || niy.contains(query);
    }).toList();
  }


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

          if (_isLoadingTeachers)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredTeachers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('Data guru tidak ditemukan.'),
              ),
            )
          else
            ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTeachers.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 20),
              itemBuilder: (_, index) {
                final teacher = filteredTeachers[index];

                return _buildTeacherCard(
                  teacher,
                  teachers.indexOf(teacher),
                );
              },
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
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF263347),
              ),
              decoration: const InputDecoration(
                hintText: 'Cari nama atau NIY guru...',
                hintStyle: TextStyle(
                  color: Color(0xFF9299A2),
                  fontSize: 11,
                ),
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
                              child: Image.network(
                                data['imageUrl'] ?? '',
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4B8068)
                                        .withValues(alpha: 0.15),
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
                                    'NIY: ${data['niy']}',
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
                            border: Border.all(
                              color: const Color(0xFFD2F4E1),
                            ),
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
                        // TOMBOL HAPUS
                        InkWell(
                          onTap: () async {
                            final konfirmasi = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Hapus Guru'),
                                content: Text(
                                  'Apakah Anda yakin ingin menghapus data ${data['name']}?\n\n'
                                  'Akun login guru juga akan dihapus secara permanen.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext, false);
                                    },
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext, true);
                                    },
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (konfirmasi == true) {
                              await _hapusGuru(
                                data['guru_id'].toString(),
                              );
                            }
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

                        // TOMBOL DETAIL
                        InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailGuruScreen(guru: data),
                              ),
                            );

                            if (result == true && mounted) {
                              _loadTeachers();
                            }
                          },
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FC),
                              border: Border.all(
                                color: const Color(0xFFE7ECF2),
                              ),
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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TambahGuruScreen(),
              ),
            );

            if (mounted) {
              _loadTeachers();
            }
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
