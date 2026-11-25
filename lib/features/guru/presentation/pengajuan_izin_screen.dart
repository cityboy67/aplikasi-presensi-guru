import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PengajuanIzinScreen extends StatefulWidget {
  const PengajuanIzinScreen({super.key});

  @override
  State<PengajuanIzinScreen> createState() => _PengajuanIzinScreenState();
}

class _PengajuanIzinScreenState extends State<PengajuanIzinScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedKategori = 'Dinas Luar/\nBimtek';
  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _delegasiController = TextEditingController();
  String? _uploadedFileName;
  String? _uploadedFileSize;
  Uint8List? _selectedPdfBytes;
  bool _isSubmitting = false;

  final SupabaseClient _supabase = Supabase.instance.client;

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

  Future<void> _pickPdf() async {
    try {
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result.isEmpty) return;

      final pickedFile = result.single;
      final fileName = pickedFile.name;
      final extension = fileName.split('.').last.toLowerCase();

      const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

      if (!allowedExtensions.contains(extension)) {
        _showMessage('Format file harus PDF, JPG, JPEG, atau PNG.');
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final fileSize = bytes.length;

      if (fileSize > 10 * 1024 * 1024) {
        _showMessage('Ukuran file maksimal 10 MB.');
        return;
      }

      setState(() {
        _selectedPdfBytes = bytes;
        _uploadedFileName = fileName;
        _uploadedFileSize =
            '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
      });
    } catch (e) {
      _showMessage('Gagal memilih file: $e');
    }
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? const Color(0xFF194432) : Colors.red.shade700,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _submitPengajuan() async {
    if (_isSubmitting) return;

    if (_keteranganController.text.trim().isEmpty) {
      _showMessage('Keterangan izin wajib diisi.');
      return;
    }

    if (_delegasiController.text.trim().isEmpty) {
      _showMessage('Delegasi mengajar dan piket wajib diisi.');
      return;
    }

    if (_selectedPdfBytes == null) {
      _showMessage('Silakan pilih dokumen pendukung.');
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showMessage('Sesi login tidak ditemukan. Silakan login kembali.');
      return;
    }

    setState(() => _isSubmitting = true);

    String? uploadedPath;

    try {
      final guru = await _supabase
          .from('guru')
          .select('guru_id, status')
          .eq('user_id', user.id)
          .maybeSingle();

      if (guru == null) {
        throw Exception('Data guru tidak ditemukan.');
      }

      if (guru['status'] != 'Aktif') {
        throw Exception('Akun guru tidak aktif.');
      }

      final guruId = guru['guru_id'].toString();

      // Format tanggal izin yang dipilih
      final tanggalIzin = _formatDate(_selectedDate);

      // ========================================
      // VALIDASI PENGAJUAN IZIN PADA TANGGAL SAMA
      // ========================================

      // Cek apakah Guru sudah memiliki pengajuan izin
      // yang mencakup tanggal yang dipilih.
      final pengajuanIzin = await _supabase
          .from('pengajuan_izin')
          .select('guru_id')
          .eq('guru_id', guruId)
          .lte('tanggal_mulai', tanggalIzin)
          .gte('tanggal_selesai', tanggalIzin);

      // Cek apakah Guru sudah memiliki pengajuan sakit
      // pada tanggal yang dipilih.
      final pengajuanSakit = await _supabase
          .from('pengajuan_sakit')
          .select('guru_id')
          .eq('guru_id', guruId)
          .eq('tanggal_sakit', tanggalIzin);

      // Jika sudah ada pengajuan, hentikan proses.
      if (pengajuanIzin.isNotEmpty ||
          pengajuanSakit.isNotEmpty) {
        _showMessage(
          'Anda sudah memiliki pengajuan pada tanggal '
          '$tanggalIzin. Silakan periksa riwayat pengajuan.',
        );
        return;
      }

      // ========================================
      // LANJUTKAN PROSES UPLOAD DOKUMEN
      // ========================================

      final extension = _uploadedFileName!
          .split('.')
          .last
          .toLowerCase();

      final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.$extension';
      uploadedPath = '$guruId/izin/$fileName';

      final contentType = switch (extension) {
        'pdf' => 'application/pdf',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        _ => 'application/octet-stream',
      };

      await _supabase.storage.from('dokumen-pengajuan').uploadBinary(
        uploadedPath,
        _selectedPdfBytes!,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );
      
      await _supabase.from('pengajuan_izin').insert({
        'guru_id': guruId,
        'jenis': 'Izin',
        'tanggal_mulai': tanggalIzin,
        'tanggal_selesai': tanggalIzin,
        'alasan': _keteranganController.text.trim(),
        'lampiran_url': uploadedPath,
        'status': 'Menunggu',
        'kategori': _selectedKategori.replaceAll('\n', ' ').trim(),
        'delegasi': _delegasiController.text.trim(),
      });

      if (!mounted) return;

      _showMessage(
        'Pengajuan izin berhasil dikirim.',
        success: true,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (uploadedPath != null) {
        try {
          await _supabase.storage
              .from('dokumen-pengajuan')
              .remove([uploadedPath]);
        } catch (_) {
          // Jika penghapusan gagal, file dapat dibersihkan dari Storage nanti.
        }
      }

      _showMessage('Gagal mengirim pengajuan: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                        'Surat undangan dinas, disposisi, atau surat keterangan '
                        '(PDF, JPG, JPEG, PNG maks 10MB)',
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
                                child: Text(
                                  _uploadedFileName!
                                      .split('.')
                                      .last
                                      .toUpperCase(),
                                  style: const TextStyle(
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
                                    _selectedPdfBytes = null;
                                    _uploadedFileName = null;
                                    _uploadedFileSize = null;
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
                          onPressed: _isSubmitting ? null : _pickPdf,
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
                    onPressed: _isSubmitting ? null : _submitPengajuan,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 22),
                    label: Text(
                      _isSubmitting
                          ? 'Mengirim Pengajuan...'
                          : 'Kirim Pengajuan Izin',
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