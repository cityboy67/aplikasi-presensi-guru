import 'package:flutter/material.dart';

class PengajuanIzinScreen extends StatefulWidget {
  const PengajuanIzinScreen({super.key});

  @override
  State<PengajuanIzinScreen> createState() => _PengajuanIzinScreenState();
}

class _PengajuanIzinScreenState extends State<PengajuanIzinScreen> {
  DateTime _selectedDate = DateTime(2026, 9, 15);
  String _selectedKategori = 'Dinas Luar/\nBimtek';
  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _delegasiController = TextEditingController();
  String? _uploadedFileName = 'Surat_Tugas.pdf';
  String? _uploadedFileSize = '3 MB • Terverifikasi Siap Unggah';

  final List<String> _kategoriOptions = [
    'Dinas Luar/\nBimtek',
    'Keperluan\nKeluarga',
    'Urusan Pribadi',
    '.... Lainnya /\nKhusus',
  ];

  @override
  void dispose() {
    _keteranganController.dispose();
    _delegasiController.dispose();
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
          'Pengajuan Izin',
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

      // Pembatas Max-Width untuk Perbaikan Dekstrop
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
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

                // Card 2: Kategori Izin (Responsif Dekstrop/Mobile)
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kategori Izin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tentukan klasifikasi diposisi izin pelajaran anda',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 14),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _kategoriOptions.length,
                        itemBuilder: (context, index) {
                          final item = _kategoriOptions[index];
                          final isSelected = _selectedKategori == item;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedKategori = item;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFD4E5DB)
                                    : const Color(0xFFEBEBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF25D366)
                                      : Colors.black38,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  item,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 3: Keterangan Izin *
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keterangan Izin *',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deskripsikan keperluan dan lokasi kegiatan kedinasan secara akurat dan jujur.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _keteranganController,
                        maxLength: 300,
                        maxLines: 5,
                        onChanged: (val) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Deskripsikan keperluan dan lokasi kegiatan...',
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
                          '${_keteranganController.text.length} / 300 Karakter',
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

                // Card 4: Delegasi Mengajar & Piket *
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delegasi Mengajar & Piket *',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _delegasiController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Tuliskan nama guru pengganti / tugas piket...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF25D366)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 5: Dokumen Pendukung *
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dokumen Pendukung *',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Surat undangan dinas, disposisi, atau surat keterangan (PDF/JPG maks 10MB)',
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
                              _uploadedFileName = 'Surat_Tugas_Terbaru.pdf';
                              _uploadedFileSize = '2.5 MB • Terverifikasi Siap Unggah';
                            });
                          },
                          icon: const Icon(Icons.description_rounded, size: 18),
                          label: Text(
                            _uploadedFileName == null
                                ? 'Unggah Dokumen'
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),

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
                          content: Text('Pengajuan Izin Berhasil Dikirim!'),
                          backgroundColor: Color(0xFF194432),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.send_rounded, size: 22),
                    label: const Text(
                      'Kirim Pengajuan Izin',
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