import 'package:flutter/material.dart';

class TambahGuruScreen extends StatefulWidget {
  const TambahGuruScreen({Key? key}) : super(key: key);

  @override
  State<TambahGuruScreen> createState() => _TambahGuruScreenState();
}

class _TambahGuruScreenState extends State<TambahGuruScreen> {
  // Controller untuk form
  final _namaController = TextEditingController();
  final _nipController = TextEditingController();
  final _emailController = TextEditingController();
  final _waController = TextEditingController();

  // Dropdown value
  String? _selectedMapel;
  final List<String> _mapelList = [
    'Matematika Terapan',
    'Teknik Jaringan',
    'Bahasa Inggris',
    'Pendidikan Agama',
  ];

  bool _isLoading = false;

  void _simpanData() {
    setState(() {
      _isLoading = true;
    });

    // Simulasi proses menyimpan data
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data guru berhasil didaftarkan!'),
          backgroundColor: Color(0xFF43816B),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                  border: Border.all(color: const Color(0xFF00D83D), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.person_outline,
                      color: Color(0xFF6D5CE7),
                      size: 28,
                    ),
                    Text(
                      'Foto Guru',
                      style: TextStyle(fontSize: 8, color: Color(0xFF6D5CE7)),
                    ),
                  ],
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
            'Maks. 2MB format JPG/PNG. Gunakan latar belakang netral Merah (Tahun ganjil) atau Biru (Tahun genap).',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Color(0xFF858585),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {}, // Action to open file picker
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
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'NIP',
            hint: 'Masukkan 18 Digit NIP atau NUPTK',
            icon: Icons.badge_outlined,
            controller: _nipController,
            keyboardType: TextInputType.number,
            maxLength: 18,
            rightLabel: '18 Digit Terverifikasi',
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
            hint: 'nama.guru@gmail.com',
            icon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Nomor WhatsApp Aktif',
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
          // Dropdown Mata Pelajaran
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
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
                  color: Colors.white,
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
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMapel,
                          isExpanded: true,
                          hint: const Text(
                            'Contoh: Matematika Terapan',
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
                          items: _mapelList.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xFF252525),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedMapel = newValue;
                            });
                          },
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
            color: Colors.white,
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
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF252525),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    counterText: "", // Hide character counter
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
