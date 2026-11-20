import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class DetailGuruScreen extends StatefulWidget {
  final Map<String, dynamic> guru;
  const DetailGuruScreen({super.key, required this.guru});

  @override
  State<DetailGuruScreen> createState() => _DetailGuruScreenState();
}

class _DetailGuruScreenState extends State<DetailGuruScreen> {
  late final TextEditingController _namaController;
  late final TextEditingController _niyController;
  late final TextEditingController _emailController;
  late final TextEditingController _waController;

  final supabase = Supabase.instance.client;

  Uint8List? _fotoBytes;
  String? _fotoNama;
  String? _fotoUrl;
  bool _isFotoLoading = false;

  String? _selectedMapel;
  final List<String> _mapelList = [
    'Matematika Terapan',
    'Teknik Jaringan',
    'Bahasa Inggris',
    'Pendidikan Agama',
    'IPA',
    'IPS',
    'PJOK',
    'Seni Budaya',
  ];

  Future<void> _pilihFoto() async {
    final picker = ImagePicker();

    final XFile? foto = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (foto == null) return;

    final bytes = await foto.readAsBytes();
    if (!mounted) return;

    setState(() {
      _fotoBytes = bytes;
      _fotoNama = foto.name;
    });
  }

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _namaController = TextEditingController(
      text: widget.guru['nama']?.toString() ?? '',
    );

    _niyController = TextEditingController(
      text: widget.guru['niy']?.toString() ?? '',
    );

    _emailController = TextEditingController(
      text: widget.guru['email']?.toString() ?? '',
    );

    _waController = TextEditingController(
      text: widget.guru['no_telepon']?.toString() ?? '',
    );

    _fotoUrl = null;
    _muatFotoGuru();
  }

  String _ambilPathStorage(String value) {
    final input = value.trim();
    if (input.isEmpty) return '';

    if (!input.startsWith('http://') && !input.startsWith('https://')) {
      return input.startsWith('/') ? input.substring(1) : input;
    }

    final uri = Uri.tryParse(input);
    if (uri == null) return input;

    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf('foto-guru');
    if (bucketIndex >= 0 && bucketIndex + 1 < segments.length) {
      return segments.skip(bucketIndex + 1).join('/');
    }

    return input;
  }

  Future<void> _muatFotoGuru() async {
    final fotoValue = widget.guru['foto_url']?.toString();
    if (fotoValue == null || fotoValue.trim().isEmpty) return;

    if (mounted) setState(() => _isFotoLoading = true);

    try {
      final path = _ambilPathStorage(fotoValue);
      if (path.isEmpty) return;

      final signedUrl = await supabase.storage
          .from('foto-guru')
          .createSignedUrl(path, 3600);

      if (!mounted) return;
      setState(() {
        _fotoUrl = signedUrl;
        _isFotoLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat foto guru: $e');
      if (!mounted) return;
      setState(() => _isFotoLoading = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _niyController.dispose();
    _emailController.dispose();
    _waController.dispose();
    super.dispose();
  }

  Future<void> _simpanData() async {
    final guruId = widget.guru['guru_id'];

    if (guruId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID guru tidak ditemukan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final niyText = _niyController.text.trim();
    if (_namaController.text.trim().isEmpty || niyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan NIY wajib diisi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^\d{7}$').hasMatch(niyText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIY harus terdiri dari 7 angka.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? fotoPathBaru;
    final fotoPathLamaValue = widget.guru['foto_url']?.toString();
    final fotoPathLama = (fotoPathLamaValue == null ||
            fotoPathLamaValue.trim().isEmpty)
        ? null
        : _ambilPathStorage(fotoPathLamaValue);

    try {
      // Upload foto baru terlebih dahulu. Foto lama belum dihapus.
      if (_fotoBytes != null) {
        final filePath =
            'guru/$niyText/${DateTime.now().millisecondsSinceEpoch}.jpg';

        await supabase.storage.from('foto-guru').uploadBinary(
          filePath,
          _fotoBytes!,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

        fotoPathBaru = filePath;
      }

      final updateData = <String, dynamic>{
        'nama': _namaController.text.trim(),
        'niy': int.parse(niyText),
        'no_telepon': _waController.text.trim(),
      };

      if (fotoPathBaru != null) {
        updateData['foto_url'] = fotoPathBaru;
      }

      // Update database. Foto lama hanya boleh dihapus setelah update sukses.
      await supabase
          .from('guru')
          .update(updateData)
          .eq('guru_id', guruId);

      // Hapus foto lama setelah database menunjuk ke foto baru.
      var fotoLamaTerhapus = true;
      if (fotoPathBaru != null &&
          fotoPathLama != null &&
          fotoPathLama.isNotEmpty &&
          fotoPathLama != fotoPathBaru) {
        try {
          await supabase.storage.from('foto-guru').remove([fotoPathLama]);
        } catch (deleteError) {
          fotoLamaTerhapus = false;
          debugPrint('Foto lama gagal dihapus: $deleteError');
        }
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isEditing = false;
        _fotoBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fotoPathBaru == null
                ? 'Data guru berhasil diperbarui!'
                : fotoLamaTerhapus
                    ? 'Data dan foto guru berhasil diperbarui. Foto lama dihapus.'
                    : 'Data dan foto baru berhasil disimpan, tetapi foto lama belum terhapus. Periksa izin DELETE Storage.',
          ),
          backgroundColor: const Color(0xFF43816B),
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      // Jika upload foto baru berhasil tetapi update database gagal,
      // hapus file baru agar tidak menjadi file yatim di Storage.
      if (fotoPathBaru != null) {
        try {
          await supabase.storage.from('foto-guru').remove([fotoPathBaru]);
        } catch (cleanupError) {
          debugPrint('Gagal membersihkan foto baru: $cleanupError');
        }
      }

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner status aktif
              _buildStatusBanner(),
              const SizedBox(height: 12),
              _buildFotoCard(),
              const SizedBox(height: 12),
              _buildIdentitasCard(),
              const SizedBox(height: 12),
              _buildAkunCard(),
              const SizedBox(height: 12),
              _buildAkademikCard(),
              const SizedBox(height: 24),
              if (_isEditing) ...[
                _buildSimpanButton(),
                const SizedBox(height: 12),
                _buildBatalButton(),
              ] else ...[
                _buildEditButton(),
                const SizedBox(height: 12),
                _buildKembaliButton(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── APP BAR ──────────────────────────────────────────────────
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
        'Detail Guru',
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

  // ── STATUS BANNER ────────────────────────────────────────────
  Widget _buildStatusBanner() {
    final status = widget.guru['status']?.toString() ?? 'Tidak diketahui';
    final isAktif = status.trim().toLowerCase() == 'aktif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAktif ? const Color(0xFFE6FAEF) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAktif ? const Color(0xFF00D477) : const Color(0xFFFFB3B3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAktif ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: isAktif ? const Color(0xFF20B76E) : const Color(0xFFF0525D),
          ),
          const SizedBox(width: 8),
          Text(
            'Status: $status',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAktif
                  ? const Color(0xFF20B76E)
                  : const Color(0xFFF0525D),
            ),
          ),
          const Spacer(),
          Text(
            'NIY: ${_niyController.text}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Color(0xFF858585),
            ),
          ),
        ],
      ),
    );
  }

  // ── CARD FOTO ────────────────────────────────────────────────
  Widget _buildFotoCard() {
    return _buildCardBase(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
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
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00D83D), width: 2),
                ),
                child: ClipOval(
                  child: _fotoBytes != null
                      ? Image.memory(
                          _fotoBytes!,
                          fit: BoxFit.cover,
                        )
                      : _isFotoLoading
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : (_fotoUrl != null
                              ? Image.network(
                                  _fotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF6D5CE7),
                                    size: 32,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF6D5CE7),
                                  size: 32,
                                )),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00D83D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _namaController.text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF252525),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.guru['guru_jenis']?.toString() ?? 'Wali Kelas',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Color(0xFF858585),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pilihFoto,
              icon: const Icon(
                Icons.upload_file,
                size: 14,
                color: Colors.white,
              ),
              label: const Text(
                'Ganti Foto',
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
        ],
      ),
    );
  }

  // ── CARD IDENTITAS ───────────────────────────────────────────
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
            hint: 'Nama lengkap',
            icon: Icons.person_outline,
            controller: _namaController,
            enabled: _isEditing,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'NIY',
            hint: 'Masukkan 7 digit NIY',
            icon: Icons.badge_outlined,
            controller: _niyController,
            keyboardType: TextInputType.number,
            maxLength: 7,
            enabled: _isEditing,
          ),
        ],
      ),
    );
  }

  // ── CARD AKUN ────────────────────────────────────────────────
  Widget _buildAkunCard() {
    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('02', 'Akun', null),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email Guru',
            hint: 'nama.guru@gmail.com',
            icon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: false,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Nomor WhatsApp Aktif',
            hint: '0812-XXXX-XXXX',
            icon: Icons.phone_outlined,
            controller: _waController,
            keyboardType: TextInputType.phone,
            enabled: _isEditing,
            rightLabelTextWidget: const Text(
              ' *Notifikasi OTP & Presensi',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00D83D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CARD AKADEMIK ────────────────────────────────────────────
  Widget _buildAkademikCard() {
    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('03', 'Akademik', null),
          const SizedBox(height: 16),
          const Text(
            'Jenis Guru',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF252525),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border.all(color: const Color(0xFFE1E5E9)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: Color(0xFF858585),
                ),
                SizedBox(width: 8),
                Text(
                  'Wali Kelas',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF252525),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BUTTONS ──────────────────────────────────────────────────
  Widget _buildEditButton() {
    return ElevatedButton.icon(
      onPressed: () => setState(() => _isEditing = true),
      icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
      label: const Text(
        'Edit Data Guru',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF43816B),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSimpanButton() {
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
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Simpan Perubahan',
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

  Widget _buildBatalButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _namaController.text = widget.guru['nama']?.toString() ?? '';
          _niyController.text = widget.guru['niy']?.toString() ?? '';
          _emailController.text = widget.guru['email']?.toString() ?? '';
          _waController.text = widget.guru['no_telepon']?.toString() ?? '';
          _fotoBytes = null;
          _isEditing = false;
        });
      },
      style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
      child: const Text(
        'Batal Edit',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF0525D),
        ),
      ),
    );
  }

  Widget _buildKembaliButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
      child: const Text(
        'Kembali ke Kelola Data',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF252525),
        ),
      ),
    );
  }

  // ── REUSABLE WIDGETS ─────────────────────────────────────────
  Widget _buildCardBase({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF00D83D)),
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
    bool enabled = true,
    String? rightLabel,
    Widget? rightLabelTextWidget,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
    int? maxLength,
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
                if (rightLabelTextWidget != null) rightLabelTextWidget,
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
          height: 42,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF8F9FA),
            border: Border.all(color: const Color(0xFFE1E5E9)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(icon, size: 16, color: const Color(0xFF858585)),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLength: maxLength,
                  enabled: enabled,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF252525),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    counterText: '',
                    hintStyle: const TextStyle(color: Color(0xFFB8BEC6)),
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
}
