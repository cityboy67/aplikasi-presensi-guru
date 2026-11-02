import 'package:flutter/material.dart';

class PengajuanSakitScreen extends StatefulWidget {
  const PengajuanSakitScreen({super.key});

  @override
  State<PengajuanSakitScreen> createState() => _PengajuanSakitScreenState();
}

class _PengajuanSakitScreenState extends State<PengajuanSakitScreen> {
  DateTime _selectedDate = DateTime(2026, 9, 15);
  String _statusPerawatan = 'Rawat Mandiri'; // 'Rawat Mandiri' atau 'Rawat Inap'
  final TextEditingController _diagnosaController = TextEditingController();
  String? _uploadedFileName = 'Surat_Dokter.pdf';
  String? _uploadedFileSize = '2 MB • Terverifikasi Siap Unggah';

  @override
  void dispose() {
    _diagnosaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00C853),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 1. AppBar Hijau Khas Desain
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C853),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF00C853),
                size: 18,
              ),
            ),
          ),
        ),
        title: const Text(
          'Pengajuan Sakit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                _buildAppBarLogo('assets/images/logo_sekolah.png', Icons.school, Colors.red.shade700),
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
      ),

      // 2. Body Utama (Ramah Mobile & Dekstrop)
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650), // Membatasi lebar agar tidak melebar di Dekstrop
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Card 1: Tanggal Izin
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Izin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBEBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.black87,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 2: Kondisi & Status Perawatan
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kondisi & Status Perawatan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // Option 1: Rawat Mandiri
                          Expanded(
                            child: _buildCareOptionCard(
                              title: 'Rawat Mandiri',
                              subtitle: 'Istirahat di rumah',
                              icon: Icons.home_outlined,
                              isSelected: _statusPerawatan == 'Rawat Mandiri',
                              onTap: () {
                                setState(() {
                                  _statusPerawatan = 'Rawat Mandiri';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Option 2: Rawat Inap
                          Expanded(
                            child: _buildCareOptionCard(
                              title: 'Rawat Inap',
                              subtitle: 'Rumah Sakit / Klinik',
                              icon: null,
                              isSelected: _statusPerawatan == 'Rawat Inap',
                              onTap: () {
                                setState(() {
                                  _statusPerawatan = 'Rawat Inap';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 3: Diagnosa / Gejala Sakit
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diagnosa / Gejala Sakit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _diagnosaController,
                        maxLength: 300,
                        maxLines: 5,
                        onChanged: (val) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Tuliskan diagnosa atau gejala sakit yang dialami...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFEBEBEB),
                          counterText: '',
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_diagnosaController.text.length} / 300 Karakter',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 4: Surat Dokter Resmi
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Surat Dokter Resmi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Surat dari dokter resmi atau klinik (PDF maks 10MB)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_uploadedFileName != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAE8FE),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.deepPurple.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PDF',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _uploadedFileName!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _uploadedFileSize!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _uploadedFileName = null;
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFE53935),
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _uploadedFileName = 'Surat_Dokter_Terbaru.pdf';
                              _uploadedFileSize = '1.8 MB • Terverifikasi Siap Unggah';
                            });
                          },
                          icon: const Icon(Icons.description_rounded, size: 18),
                          label: Text(
                            _uploadedFileName == null
                                ? 'Unggah Surat Dokter'
                                : 'Ganti atau Unggah Dokumen Lain',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0E0FF),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 5: Disclaimer Peringatan Hukum
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF25D366),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dengan menekan tombol kirim, saya menyatakan bahwa dokumen medis ini asli dan sah secara hukum. Segala bentuk pemalsuan surat medis dikenai sanksi kedisiplinan ASN/Kepegawaian',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),

      // 3. Tombol Kirim Pengajuan Sakit
      bottomNavigationBar: Container(
        color: const Color(0xFF00C853),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pengajuan Sakit Berhasil Dikirim!'),
                          backgroundColor: Color(0xFF194432),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.send_rounded, size: 22),
                    label: const Text(
                      'Kirim Pengajuan Sakit',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF194432),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget Kartu Opsi Perawatan (Rawat Mandiri / Rawat Inap)
  Widget _buildCareOptionCard({
    required String title,
    required String subtitle,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE5E8E6) : const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.black26,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (icon != null)
                    Icon(icon, size: 22, color: Colors.black)
                  else
                    const SizedBox.shrink(),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: isSelected ? Colors.black : Colors.grey.shade500,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF25D366),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
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
}