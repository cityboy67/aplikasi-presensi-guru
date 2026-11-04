import 'package:flutter/material.dart';

class DetailGuruScreen extends StatefulWidget {
  final Map<String, dynamic> guru;
  const DetailGuruScreen({super.key, required this.guru});

  @override
  State<DetailGuruScreen> createState() => _DetailGuruScreenState();
}

class _DetailGuruScreenState extends State<DetailGuruScreen> {
  late final TextEditingController _namaController;
  late final TextEditingController _nipController;
  late final TextEditingController _emailController;
  late final TextEditingController _waController;

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

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Isi data dari guru yang dipilih
    _namaController = TextEditingController(
      text: widget.guru['name'] as String? ?? '',
    );
    _nipController = TextEditingController(
      text: widget.guru['nip'] as String? ?? '',
    );
    _emailController = TextEditingController(
      text:
          '${(widget.guru['name'] as String? ?? 'guru').toLowerCase().replaceAll(' ', '.')}@sekolah.sch.id',
    );
    _waController = TextEditingController(text: '0812-XXXX-XXXX');
    _selectedMapel = _mapelList.contains(widget.guru['subject'])
        ? widget.guru['subject'] as String
        : null;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _waController.dispose();
    super.dispose();
  }

  void _simpanData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data guru berhasil diperbarui!'),
        backgroundColor: Color(0xFF43816B),
      ),
    );
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
    final status = widget.guru['status'] as String? ?? 'AKTIF';
    final isAktif = status == 'AKTIF';
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
            'NIP: ${widget.guru['nip'] ?? '-'}',
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
                  child: Image.asset(
                    widget.guru['image'] as String? ??
                        'assets/images/foto_guru.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Color(0xFF6D5CE7),
                          size: 32,
                        ),
                        Text(
                          // Ambil inisial dari nama
                          (widget.guru['name'] as String? ?? 'G')
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6D5CE7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
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
            widget.guru['name'] as String? ?? '',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF252525),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.guru['subject'] as String? ?? '',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Color(0xFF858585),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {},
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
            label: 'NIP',
            hint: '18 Digit NIP atau NUPTK',
            icon: Icons.badge_outlined,
            controller: _nipController,
            keyboardType: TextInputType.number,
            maxLength: 18,
            rightLabel: '18 Digit Terverifikasi',
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
            enabled: _isEditing,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Mata Pelajaran Utama',
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
                  color: _isEditing ? Colors.white : const Color(0xFFF8F9FA),
                  border: Border.all(color: const Color(0xFFE1E5E9)),
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 16,
                      color: Color(0xFF858585),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isEditing
                          ? DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedMapel,
                                isExpanded: true,
                                hint: const Text(
                                  'Pilih mata pelajaran',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Color(0xFFB8BEC6),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF858585),
                                ),
                                items: _mapelList.map((v) {
                                  return DropdownMenuItem<String>(
                                    value: v,
                                    child: Text(
                                      v,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Color(0xFF252525),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedMapel = v),
                              ),
                            )
                          : Text(
                              _selectedMapel ?? widget.guru['subject'] ?? '-',
                              style: const TextStyle(
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
      onPressed: () => setState(() => _isEditing = false),
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
