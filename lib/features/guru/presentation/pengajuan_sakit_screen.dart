import 'dart:typed_data';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PengajuanSakitScreen extends StatefulWidget {
  const PengajuanSakitScreen({super.key});

  @override
  State<PengajuanSakitScreen> createState() => _PengajuanSakitScreenState();
}

class _PengajuanSakitScreenState extends State<PengajuanSakitScreen> {
  DateTime _selectedDate = DateTime.now();
  String _statusPerawatan = 'Rawat Mandiri'; // 'Rawat Mandiri' atau 'Rawat Inap'
  final TextEditingController _diagnosaController = TextEditingController();
  String? _uploadedFileName;
  String? _uploadedFileSize;
  Uint8List? _selectedPdfBytes;
  bool _isSubmitting = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _diagnosaController.dispose();
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

      if (bytes.length > 10 * 1024 * 1024) {
        _showMessage('Ukuran file maksimal 10 MB.');
        return;
      }

      setState(() {
        _selectedPdfBytes = bytes;
        _uploadedFileName = fileName;
        _uploadedFileSize =
            '${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB';
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

    if (_diagnosaController.text.trim().isEmpty) {
      _showMessage('Diagnosa atau gejala sakit wajib diisi.');
      return;
    }
    if (_selectedPdfBytes == null) {
      _showMessage('Silakan pilih surat dokter sebagai lampiran.');
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

      // Format tanggal yang dipilih
      final tanggalSakit = _formatDate(_selectedDate);

      // ========================================
      // VALIDASI PENGAJUAN SAKIT PADA TANGGAL SAMA
      // ========================================

      // Cek apakah Guru sudah mengajukan sakit
      // pada tanggal yang sama.
      final pengajuanSakit = await _supabase
          .from('pengajuan_sakit')
          .select('guru_id')
          .eq('guru_id', guruId)
          .eq('tanggal_sakit', tanggalSakit);

      // Cek apakah Guru sudah memiliki pengajuan izin
      // yang mencakup tanggal sakit tersebut.
      final pengajuanIzin = await _supabase
          .from('pengajuan_izin')
          .select('guru_id')
          .eq('guru_id', guruId)
          .lte('tanggal_mulai', tanggalSakit)
          .gte('tanggal_selesai', tanggalSakit);

      // Jika salah satu ditemukan, hentikan pengajuan.
      if (pengajuanSakit.isNotEmpty ||
          pengajuanIzin.isNotEmpty) {
        _showMessage(
          'Anda sudah memiliki pengajuan pada tanggal '
          '$tanggalSakit. Silakan periksa riwayat pengajuan.',
        );
        return;
      }

      final extension = _uploadedFileName!
          .split('.')
          .last
          .toLowerCase();

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';

      uploadedPath = '$guruId/sakit/$fileName';
      uploadedPath = '$guruId/sakit/$fileName';

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

      await _supabase.from('pengajuan_sakit').insert({
        'guru_id': guruId,
        'tanggal_sakit': tanggalSakit,
        'status_perawatan': _statusPerawatan,
        'diagnosa': _diagnosaController.text.trim(),
        'lampiran_url': uploadedPath,
        'status': 'Menunggu',
      });

      if (!mounted) return;
      _showMessage('Pengajuan sakit berhasil dikirim.', success: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (uploadedPath != null) {
        try {
          await _supabase.storage
              .from('dokumen-pengajuan')
              .remove([uploadedPath]);
        } catch (_) {
          // File yang gagal dibersihkan dapat dihapus dari Storage nanti.
        }
      }
      _showMessage('Gagal mengirim pengajuan: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                        'Surat dari dokter resmi atau klinik '
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
                                    _uploadedFileName = null;
                                    _uploadedFileSize = null;
                                    _selectedPdfBytes = null;
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
                          : 'Kirim Pengajuan Sakit',
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