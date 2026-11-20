import 'package:flutter/material.dart';
import 'pengajuan_izin_screen.dart';
import 'pengajuan_sakit_screen.dart';
import 'edit_profile_screen.dart';
import '../../auth/presentation/role_selection_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'presensi_camera_screen.dart';
import '../data/presensi_service.dart';
import 'ganti_password_guru_screen.dart';

class GuruDashboardScreen extends StatefulWidget {
  const GuruDashboardScreen({super.key});

  @override
  State<GuruDashboardScreen> createState() => _GuruDashboardScreenState();
}

class _GuruDashboardScreenState extends State<GuruDashboardScreen> {
  int _selectedBottomIndex = 0; // 0: Absen, 1: Perizinan, 2: Profil

  // Waktu dalam zona waktu WIB (UTC+7)
  DateTime _waktuSekarang = DateTime.now()
      .toUtc()
      .add(const Duration(hours: 7));

  Timer? _clockTimer;

  final supabase = Supabase.instance.client;

  // Guru profile information
  String _guruName = 'Memuat...';
  String _guruEmail = '';
  String _guruJenis = '';
  String? _guruFotoUrl;

  bool _isLoadingProfile = true;

  // Device information
  String? _guruId;

  String _deviceNama = 'Belum terdaftar';
  String _deviceIdentifier = '-';
  String _deviceStatus = 'Belum Terikat';

  bool _isLoadingDevice = true;

  // Location information
  double? _latitudeGuru;
  double? _longitudeGuru;
  double? _jarakSekolah;

  double? _latitudeSekolah;
  double? _longitudeSekolah;
  int _radiusSekolah = 100;

  String _statusLokasi = 'Memuat lokasi...';
  bool _isLoadingLokasi = true;
  bool _dalamRadius = false;
  
  // Foto bukti presensi
  File? _fotoBukti;

  // Status pengiriman presensi
  bool _isSubmittingPresensi = false;

  // History presensi
  List<Map<String, dynamic>> _historyData = [];
  bool _isLoadingHistory = true;

  // Location information
  @override
  void initState() {
    super.initState();

    _loadGuruProfile();
    _loadLokasiSekolah();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _waktuSekarang = DateTime.now()
              .toUtc()
              .add(const Duration(hours: 7));
        });
      },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // Load device information based on guru_id
  Future<void> _loadDeviceInfo() async {
    try {
      if (_guruId == null) return;

      final response = await supabase
          .from('device')
          .select(
            'device_nama, device_identifier, status_binding',
          )
          .eq('guru_id', _guruId!)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        if (response != null) {
          _deviceNama = response['device_nama'] ?? '-';
          _deviceIdentifier =
              response['device_identifier'] ?? '-';
          _deviceStatus =
              response['status_binding'] ?? 'Belum Terikat';
        } else {
          _deviceNama = 'Belum terdaftar';
          _deviceIdentifier = '-';
          _deviceStatus = 'Belum Terikat';
        }

        _isLoadingDevice = false;
      });
    } catch (e) {
      debugPrint('Gagal mengambil informasi perangkat: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingDevice = false;
      });
    }
  }

  // Load lokasi sekolah from Supabase
  Future<void> _loadLokasiSekolah() async {
    try {
      final response = await supabase
          .from('lokasi_presensi')
          .select('latitude, longitude, radius')
          .eq('status', true)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        throw Exception('Lokasi sekolah belum tersedia.');
      }

      _latitudeSekolah =
          (response['latitude'] as num).toDouble();

      _longitudeSekolah =
          (response['longitude'] as num).toDouble();

      _radiusSekolah =
          (response['radius'] as num).toInt();

      await _ambilLokasiGuru();
    } catch (e) {
      debugPrint('Gagal mengambil lokasi sekolah: $e');

      if (!mounted) return;

      setState(() {
        _statusLokasi = 'Lokasi sekolah tidak tersedia';
        _isLoadingLokasi = false;
      });
    }
  }

  // Ambil lokasi guru menggunakan Geolocator
  Future<void> _ambilLokasiGuru() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('GPS HP belum diaktifkan.');
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi belum diberikan.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi ditolak permanen. '
          'Aktifkan melalui pengaturan aplikasi.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final jarak = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _latitudeSekolah!,
        _longitudeSekolah!,
      );

      if (!mounted) return;

      setState(() {
        _latitudeGuru = position.latitude;
        _longitudeGuru = position.longitude;
        _jarakSekolah = jarak;

        _dalamRadius = jarak <= _radiusSekolah;

        _statusLokasi = _dalamRadius
            ? 'DALAM RADIUS SEKOLAH'
            : 'DI LUAR RADIUS SEKOLAH';

        _isLoadingLokasi = false;
      });
    } catch (e) {
      debugPrint('Gagal mengambil GPS: $e');

      if (!mounted) return;

      setState(() {
        _statusLokasi = e.toString().replaceFirst('Exception: ', '');
        _isLoadingLokasi = false;
        _dalamRadius = false;
      });
    }
  }

  // Load guru profile information from Supabase
  Future<void> _loadGuruProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Pengguna belum login.');
      }

      final response = await supabase
          .from('guru')
          .select(
            'guru_id, nama, email, niy, guru_jenis, '
            'status, foto_url, no_telepon',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        throw Exception('Data guru tidak ditemukan.');
      }

      // Ambil data profil terlebih dahulu.
      final nama = response['nama']?.toString() ?? '-';
      final email =
          response['email']?.toString() ?? user.email ?? '-';
      final jenis = response['guru_jenis']?.toString() ?? '-';

      if (!mounted) return;

      setState(() {
        _guruId = response['guru_id']?.toString();
        _guruName = nama;
        _guruEmail = email;
        _guruJenis = jenis;
        _isLoadingProfile = false;
      });

      if (_guruId != null) {
        await _loadDeviceInfo();
        await _loadHistoryPresensi();
      }

      // Ambil foto secara terpisah agar kegagalan foto
      // tidak menghambat pemuatan profil.
      String? fotoUrl;
      final fotoPath = response['foto_url']?.toString();

      if (fotoPath != null && fotoPath.isNotEmpty) {
        try {
          fotoUrl = await supabase.storage
              .from('foto-guru')
              .createSignedUrl(fotoPath, 3600);
        } catch (e) {
          debugPrint('Gagal mengambil foto guru: $e');
          debugPrint('Path foto pada database: $fotoPath');
        }
      }

      if (!mounted) return;

      setState(() {
        _guruFotoUrl = fotoUrl;
      });

    } catch (e) {
      debugPrint('Gagal mengambil profil guru: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat profil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load history presensi for the guru
  Future<void> _loadHistoryPresensi() async {
    try {
      if (_guruId == null) return;

      final response = await supabase
          .from('presensi')
          .select('tanggal, jam, status')
          .eq('guru_id', _guruId!)
          .order('tanggal', ascending: false)
          .order('jam', ascending: false)
          .limit(5);

      if (!mounted) return;

      setState(() {
        _historyData = List<Map<String, dynamic>>.from(response);
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint('Gagal mengambil riwayat presensi: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedBottomIndex == 1
          ? const Color(0xFFDBDBDB)
          : const Color(0xFFF8FAF9),

      appBar: _selectedBottomIndex != 1
          ? AppBar(
              backgroundColor: const Color(0xFF00C853),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                onPressed: () {},
              ),
              title: _selectedBottomIndex == 2
                  ? const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    )
                  : null,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: [
                      _buildAppBarLogo('assets/images/logo_upi.png', Icons.school, Colors.red.shade700),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.0),
                        child: Text(
                          'x',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _buildAppBarLogo('assets/images/logo_mitra.png', Icons.public, Colors.teal.shade700),
                    ],
                  ),
                ),
              ],
            )
          : null,

      body: SafeArea(
        top: _selectedBottomIndex == 1 ? false : true,
        bottom: false,
        child: IndexedStack(
          index: _selectedBottomIndex,
          children: [
            _buildAbsenView(),
            _buildPerizinanView(),
            _buildProfilView(),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // 1. MENU ABSEN (INDEX 0)
  Widget _buildAbsenView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 16),
              _buildDateTimeBanner(),
              const SizedBox(height: 14),
              _buildDeviceCard(),
              const SizedBox(height: 14),
              _buildLocationMapCard(),
              const SizedBox(height: 14),
              _buildPhotoEvidenceCard(),
              const SizedBox(height: 16),
              _buildSubmitButton(),
              const SizedBox(height: 24),
              _buildHistorySection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 2. MENU PERIZINAN (INDEX 1)
  Widget _buildPerizinanView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final headerHeight = constraints.maxHeight * 0.32;

        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight < 180 ? 180 : headerHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/bg_alaqsha.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: const Color(0xFF1B4D4F));
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Container(color: const Color(0x40000000)),
                  ),
                  const Positioned(
                    left: 24,
                    bottom: 36,
                    child: Text(
                      'Perizinan',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned.fill(
              top: (headerHeight < 180 ? 180 : headerHeight) - 24,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFDBDBDB),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _buildPermitOptionCard(
                                title: 'Izin',
                                icon: Icons.groups_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PengajuanIzinScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPermitOptionCard(
                                title: 'Sakit',
                                icon: Icons.add_box_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PengajuanSakitScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 3. MENU PROFIL (INDEX 2)
  Widget _buildProfilView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 4),
                ),
                child: ClipOval(
                  child: _guruFotoUrl != null
                      ? Image.network(
                          _guruFotoUrl!,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 32,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                _guruName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                _guruEmail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 36),

             _buildProfileMenuCard(
              title: 'Edit Profile',
              icon: Icons.person_outline_rounded,
              onTap: () async {
                final dynamic result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      initialName: _guruName,
                      initialEmail: _guruEmail,
                      initialAddress: '',
                    ),
                  ),
                );

                if (result != null && result is Map) {
                  setState(() {
                    _guruName = (result['name'] as String?) ?? _guruName;
                    _guruEmail = (result['email'] as String?) ?? _guruEmail;
                  });

                  await _loadGuruProfile();
                }
              },
            ),
            const SizedBox(height: 16),

              _buildProfileMenuCard(
                title: 'Settings',
                icon: Icons.settings_outlined,
                onTap: () {
                  _showSettingsBottomSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: Color(0xFF194432)),
                  title: const Text('Ubah Password', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GantiPasswordGuruScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.orange),
                  title: const Text('Keluar (Logout)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                  onTap: () {
                    Navigator.pop(context);
                    _showConfirmLogoutDialog(context);
                  },
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: const Text('Hapus Akun Permanen', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showConfirmDeleteAccountDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF194432),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Tindakan ini tidak dapat dibatalkan. Seluruh data presensi Anda akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus Akun', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.black, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      color: _selectedBottomIndex == 1
          ? const Color(0xFF00C853)
          : const Color(0xFFF8FAF9),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF194432),
            borderRadius: BorderRadius.circular(35),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Absen',
                icon: Icons.assignment_rounded,
              ),
              _buildNavItem(
                index: 1,
                label: 'Perizinan',
                icon: Icons.description_rounded,
              ),
              _buildNavItem(
                index: 2,
                label: 'Profil',
                icon: Icons.account_circle_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedBottomIndex == index;

    return InkWell(
      onTap: () {
        if (_selectedBottomIndex != index) {
          setState(() {
            _selectedBottomIndex = index;
          });
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF56C98B) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF194432) : Colors.white,
              size: isSelected ? 20 : 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF194432),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarLogo(String assetPath, IconData fallbackIcon, Color fallbackColor) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(fallbackIcon, color: fallbackColor, size: 18);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: ClipOval(
            child: _guruFotoUrl != null
                ? Image.network(
                    _guruFotoUrl!,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 32,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 32,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _guruName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _guruJenis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  
  Widget _buildDateTimeBanner() {
    const namaHari = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];

    const namaBulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final hari = namaHari[_waktuSekarang.weekday % 7];
    final tanggal = _waktuSekarang.day;
    final bulan = namaBulan[_waktuSekarang.month - 1];
    final tahun = _waktuSekarang.year;

    final jam = _waktuSekarang.hour.toString().padLeft(2, '0');
    final menit = _waktuSekarang.minute.toString().padLeft(2, '0');
    final detik = _waktuSekarang.second.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF16B555),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '$hari, $tanggal $bulan $tahun',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$jam:$menit:$detik',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 4. WIDGET KARTU PERANGKAT
  Widget _buildDeviceCard() {
    final isTerikat = _deviceStatus == 'Terikat' || _deviceStatus == 'Aktif';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF52C488),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smartphone_rounded,
              color: Color(0xFF52C488),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingDevice
                      ? 'Memuat perangkat...'
                      : _deviceNama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _isLoadingDevice
                      ? 'Memeriksa status perangkat'
                      : 'Status: $_deviceStatus',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            _isLoadingDevice
                ? Icons.hourglass_empty
                : isTerikat
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
            color: _isLoadingDevice
                ? Colors.grey
                : isTerikat
                    ? const Color(0xFF52C488)
                    : Colors.orange,
            size: 22,
          ),
        ],
      ),
    );
  }

  // 5. WIDGET KARTU PETA LOKASI 
  Widget _buildLocationMapCard() {
    final bool lokasiTersedia =
        _latitudeSekolah != null &&
        _longitudeSekolah != null;

    final bool gpsTersedia =
        _latitudeGuru != null &&
        _longitudeGuru != null;

    final Color statusColor = _isLoadingLokasi
        ? Colors.orange
        : _dalamRadius
            ? const Color(0xFF52C488)
            : Colors.red;

    final LatLng? posisiSekolah = lokasiTersedia
        ? LatLng(_latitudeSekolah!, _longitudeSekolah!)
        : null;

    final LatLng? posisiGuru = gpsTersedia
        ? LatLng(_latitudeGuru!, _longitudeGuru!)
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF52C488),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // STATUS LOKASI
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFE67E22),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isLoadingLokasi
                        ? 'MEMERIKSA LOKASI...'
                        : _statusLokasi,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isLoadingLokasi)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _dalamRadius
                            ? Icons.check_circle_rounded
                            : Icons.location_off_rounded,
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _isLoadingLokasi
                            ? null
                            : _ambilLokasiGuru,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF1B6A42),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // PETA INTERAKTIF
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: posisiSekolah == null
                  ? const Center(
                      child: Text(
                        'Lokasi sekolah belum tersedia',
                      ),
                    )
                  : FlutterMap(
                      options: MapOptions(
                          initialCenter: posisiSekolah,
                          initialZoom: 16,
                          minZoom: 5,
                          maxZoom: 19,
                          onMapReady: () {
                            debugPrint('MAP BERHASIL DIINISIALISASI');
                          },
                        ),
                      children: [    
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.flutter_application_1',
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint('MAP TILE ERROR: $error');
                          },
                        ),

                        // LINGKARAN RADIUS SEKOLAH
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: posisiSekolah,
                              radius: _radiusSekolah.toDouble(),
                              useRadiusInMeter: true,
                              color: const Color(0x3352C488),
                              borderColor:
                                  const Color(0xFF16B555),
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),

                        // MARKER SEKOLAH DAN GURU
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: posisiSekolah,
                              width: 45,
                              height: 45,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                            if (posisiGuru != null)
                              Marker(
                                point: posisiGuru,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 32,
                                ),
                              ),
                          ],
                        ),

                        const RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              'OpenStreetMap contributors',
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // INFORMASI JARAK
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.social_distance_rounded,
                color: statusColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _jarakSekolah != null
                      ? 'Jarak ke sekolah: ${_jarakSekolah!.round()} meter'
                      : 'Jarak belum tersedia',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Radius presensi: $_radiusSekolah meter',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoEvidenceCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF52C488), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: Colors.grey.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Bukti Foto Presensi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _fotoBukti != null
                  ? Image.file(
                      _fotoBukti!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/guru_photo1.png',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final hasilFoto = await Navigator.push<File>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PresensiCameraScreen(),
                      ),
                    );

                    if (hasilFoto != null && mounted) {
                      setState(() {
                        _fotoBukti = hasilFoto;
                      });
                    }
                  },
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                    size: 13,
                  ),
                  label: const Text(
                    'Ambil Ulang',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xE635775B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmittingPresensi
            ? null
            : () async {
                // Pastikan foto sudah diambil.
                if (_fotoBukti == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Silakan ambil foto bukti presensi terlebih dahulu.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                setState(() {
                  _isSubmittingPresensi = true;
                });

                try {
                  final service = PresensiService();

                  final hasil = await service.kirimPresensi(
                    foto: _fotoBukti!,
                  );

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        hasil['message']?.toString() ??
                            'Terjadi kesalahan saat mengirim presensi.',
                      ),
                      backgroundColor: hasil['success'] == true
                          ? const Color(0xFF35775B)
                          : Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );

                  if (hasil['success'] == true) {
                    debugPrint(
                      'PRESENSI BERHASIL: ${hasil['foto_bukti']}',
                    );
                    debugPrint(
                      'JARAK SEKOLAH: ${hasil['jarak']} meter',
                    );
                  }
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengirim presensi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isSubmittingPresensi = false;
                    });
                  }
                }
              },
        icon: _isSubmittingPresensi
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded, size: 20),
        label: Text(
          _isSubmittingPresensi
              ? 'Mengirim Presensi...'
              : 'Kirim Absen',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF35775B),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF35775B),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    const namaHari = [
      'Minggu', 'Senin', 'Selasa', 'Rabu',
      'Kamis', 'Jumat', 'Sabtu'
    ];

    const namaBulan = [
      'Januari', 'Februari', 'Maret', 'April',
      'Mei', 'Juni', 'Juli', 'Agustus',
      'September', 'Oktober', 'November', 'Desember'
    ];

    String formatTanggal(String tanggal) {
      final date = DateTime.parse(tanggal);

      return '${namaHari[date.weekday % 7]}, '
          '${date.day} ${namaBulan[date.month - 1]} ${date.year}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Presensi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE5ECE8),
                Color(0xFFA0AAA4),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: _isLoadingHistory
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _historyData.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Belum ada riwayat presensi.'),
                      ),
                    )
                  : Column(
                      children: List.generate(
                        _historyData.length,
                        (index) {
                          final item = _historyData[index];
                          final isLast =
                              index == _historyData.length - 1;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formatTanggal(
                                              item['tanggal'].toString(),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.exit_to_app_rounded,
                                                color: Color(0xFF16B555),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item['status']?.toString() ??
                                                    'Hadir',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      item['jam']?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                const Divider(
                                  color: Colors.black12,
                                  height: 12,
                                  thickness: 0.8,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildPermitOptionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF25D366),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.black,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}