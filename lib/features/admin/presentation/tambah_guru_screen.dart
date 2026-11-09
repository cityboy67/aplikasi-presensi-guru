import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TambahGuruScreen extends StatefulWidget {
  const TambahGuruScreen({Key? key}) : super(key: key);

  @override
  State<TambahGuruScreen> createState() => _TambahGuruScreenState();
}

  class _TambahGuruScreenState extends State<TambahGuruScreen> {
    // Controller untuk form
    final _formKey = GlobalKey<FormState>();
    final _namaController = TextEditingController();
    final _niyController = TextEditingController();
    final _emailController = TextEditingController();
    final _waController = TextEditingController();
    final supabase = Supabase.instance.client;

    // Variable untuk menyimpan foto guru
    Uint8List? _fotoGuruBytes;
    String? _fotoGuruName;

    final ImagePicker _imagePicker = ImagePicker();

    //Fungsi untuk memilih foto dari galeri
    Future<void> _pilihFoto() async {
      try {
        final XFile? foto = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );

        if (foto == null) return;

        final bytes = await foto.readAsBytes();

        // Validasi ukuran maksimal 2 MB.
        if (bytes.length > 2 * 1024 * 1024) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran foto maksimal 2 MB.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _fotoGuruBytes = bytes;
          _fotoGuruName = foto.name;
        });
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Dropdown value
    final String _guruJenis = 'Wali Kelas';

    bool _isLoading = false;

    Future<void> _simpanData() async {
      // 1. Validasi formulir
      if (!_formKey.currentState!.validate()) return;

      if (_fotoGuruBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto guru wajib dipilih'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_isLoading) return;

      setState(() => _isLoading = true);

      try {
        final nama = _namaController.text.trim();
        final niy = _niyController.text.trim();
        final email = _emailController.text.trim().toLowerCase();
        final noTelepon = _waController.text.trim();

        // 2. Upload foto ke Supabase Storage
        final fotoPath = await _uploadFotoGuru(niy);

        // 3. Panggil Edge Function untuk membuat akun guru
        final result = await supabase.functions.invoke(
          'buat-akun-guru',
          body: {
            'nama': nama,
            'niy': niy,
            'email': email,
            'no_telepon': noTelepon,
            'foto_url': fotoPath,
          },
        );

        // 4. Periksa hasil respons
        final data = Map<String, dynamic>.from(result.data as Map);

        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Gagal membuat akun guru');
        }

        final password = data['password_awal']?.toString() ?? '';

        if (password.isEmpty) {
          throw Exception('Password awal tidak diterima dari server');
        }

        if (!mounted) return;

        // 5. Tampilkan informasi akun kepada Admin
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Guru Berhasil Ditambahkan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Akun guru berhasil dibuat. Berikan informasi berikut kepada guru:'),
                  const SizedBox(height: 16),
                  const Text('Nama Guru'),
                  Text(nama),
                  const SizedBox(height: 10),
                  const Text('NIY'),
                  SelectableText(niy),
                  const SizedBox(height: 10),
                  const Text('Email'),
                  SelectableText(email),
                  const SizedBox(height: 10),
                  const Text('Password Awal'),
                  SelectableText(
                    password,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Simpan password ini sebelum menutup dialog. '
                    'Password tidak dapat dilihat kembali dari database.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Selesai'),
                ),
              ],
            );
          },
        );

        if (!mounted) return;

        // 6. Bersihkan formulir setelah berhasil
        _namaController.clear();
        _niyController.clear();
        _emailController.clear();
        _waController.clear();

        setState(() {
          _fotoGuruBytes = null;
          _fotoGuruName = null;
        });

      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan guru: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }

  // Fungsi untuk mengunggah foto guru ke Supabase Storage
  Future<String> _uploadFotoGuru(String niy) async {
    if (_fotoGuruBytes == null || _fotoGuruName == null) {
      throw Exception('Foto guru belum dipilih');
    }

    final extension = _fotoGuruName!.split('.').last.toLowerCase();

    final filePath =
        'guru/$niy/${DateTime.now().millisecondsSinceEpoch}.$extension';

    final contentType = extension == 'png'
        ? 'image/png'
        : 'image/jpeg';

    await supabase.storage.from('foto-guru').uploadBinary(
      filePath,
      _fotoGuruBytes!,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: false,
      ),
    );

    return filePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFotoResmiCard(),
                const SizedBox(height: 12),
                _buildIdentitasCard(),
                const SizedBox(height: 12),
                _buildAkunCard(),
                const SizedBox(height: 12),
                _buildAkademikCard(),
                const SizedBox(height: 24),
                _buildPrimaryButton(),
                const SizedBox(height: 12),
                _buildSecondaryButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER (APP BAR) ---
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF00D83D),
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chevron_left,
            color: Color(0xFF00D83D),
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Tambah Guru',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        Row(
          children: [
            _buildLogo('assets/images/logo_upi.png'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'x',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildLogo('assets/images/logo_mitra.png'),
            const SizedBox(width: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildLogo(String path) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Image.asset(
            path,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.school, size: 14, color: Color(0xFF00D83D)),
          ),
        ),
      ),
    );
  }

  // --- 2. CARD FOTO RESMI ---
  Widget _buildFotoResmiCard() {
    return _buildCardBase(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF6D5CE7),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Foto Resmi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF252525),
                    ),
                  ),
                ],
              ),
              const Text(
                '* Wajib',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF4545),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Circle Image Preview
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00D83D),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _fotoGuruBytes != null
                      ? Image.memory(
                        _fotoGuruBytes!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Color(0xFF6D5CE7),
                              size: 28,
                            ),
                            Text(
                              'Foto Guru',
                              style: TextStyle(
                                fontSize: 8,
                                color: Color(0xFF6D5CE7),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00D83D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Maks. 2MB format JPG/JPEG/PNG. Gunakan latar belakang netral Merah (Tahun ganjil) atau Biru (Tahun genap).',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Color(0xFF858585),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _pilihFoto, // Action to open file picker
            icon: const Icon(Icons.upload_file, size: 14, color: Colors.white),
            label: const Text(
              'Pilih File Foto',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D83D),
              elevation: 0,
              minimumSize: const Size(120, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. CARD IDENTITAS & KEPEGAWAIAN ---
  Widget _buildIdentitasCard() {
    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('01', 'Identitas & Kepegawaian', 'Data Pokok'),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Nama Lengkap & Gelar Akademik',
            isRequired: true,
            hint: 'Contoh: Siti Rahmawati, S.Pd, M.Pd.',
            icon: Icons.person_outline,
            controller: _namaController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'NIY',
            isRequired: true,
            hint: 'Masukkan 7 Digit NIY',
            icon: Icons.badge_outlined,
            controller: _niyController,
            keyboardType: TextInputType.number,
            maxLength: 7,
            rightLabel: '7 Digit Terverifikasi',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'NIY wajib diisi';
              }
              if (!RegExp(r'^\d{7}$').hasMatch(value.trim())) {
                return 'NIY harus terdiri dari 7 digit';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // --- 4. CARD AKUN ---
  Widget _buildAkunCard() {
    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('02', 'Akun', null),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email Guru',
            isRequired: true,
            hint: 'nama.guru@gmail.com',
            icon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email wajib diisi';
              }
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value.trim())) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Nomor WhatsApp Aktif',
            isRequired: true,
            hint: '0812-XXXX-XXXX',
            icon: Icons.phone_outlined,
            controller: _waController,
            keyboardType: TextInputType.phone,
            rightLabelTextWidget: const Text(
              ' *Notifikasi OTP & Presensi',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00D83D),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nomor WhatsApp wajib diisi';
              }
              if (!RegExp(r'^[0-9+]{10,15}$').hasMatch(value.trim())) {
                return 'Nomor WhatsApp tidak valid';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  
  // --- 5. CARD AKADEMIK ---
  Widget _buildAkademikCard() {
    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('03', 'Akademik', null),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Jenis Guru',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF252525),
                    ),
                  ),
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4545),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFE1E5E9),
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: const [
                    Icon(
                      Icons.school_outlined,
                      size: 16,
                      color: Color(0xFF858585),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wali Kelas',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF252525),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // --- REUSABLE WIDGETS ---

  Widget _buildCardBase({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF00D83D), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String badgeNum, String title, String? trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEAFE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeNum,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6D5CE7),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF252525),
              ),
            ),
          ],
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Color(0xFF858585),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    String? rightLabel,
    Widget? rightLabelTextWidget,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF252525),
                  ),
                ),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4545),
                    ),
                  ),
                if (rightLabelTextWidget != null)
                  rightLabelTextWidget,
              ],
            ),
            if (rightLabel != null)
              Text(
                rightLabel,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Color(0xFF858585),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 42),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE1E5E9)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF858585),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLength: maxLength,
                  validator: validator,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF252525),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    counterText: "",
                    hintStyle: const TextStyle(
                      color: Color(0xFFB8BEC6),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(
                      right: 12,
                      top: 12,
                      bottom: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _simpanData,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF43816B),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.person_add_alt_1, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Simpan & Daftarkan Guru',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSecondaryButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
      child: const Text(
        'Batal & Kembali ke Kelola Data',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF252525),
        ),
      ),
    );
  }
}
