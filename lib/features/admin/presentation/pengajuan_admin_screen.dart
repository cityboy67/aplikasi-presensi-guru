import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PengajuanAdminScreen extends StatefulWidget {
  const PengajuanAdminScreen({super.key});

  @override
  State<PengajuanAdminScreen> createState() => _PengajuanAdminScreenState();
}

class _PengajuanAdminScreenState extends State<PengajuanAdminScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  static const Color _green = Color(0xFF43816B);
  static const Color _background = Color(0xFFF5F7F8);
  static const Color _purple = Color(0xFF6557D9);

  String _filter = 'Semua';
  String _search = '';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _supabase
            .from('pengajuan_izin')
            .select(
              'pengajuan_id, guru_id, jenis, kategori, delegasi, '
              'tanggal_mulai, tanggal_selesai, alasan, lampiran_url, '
              'status, catatan_admin, created_at',
            ),
        _supabase
            .from('pengajuan_sakit')
            .select(
              'pengajuan_id, guru_id, tanggal_sakit, status_perawatan, '
              'diagnosa, lampiran_url, status, catatan_admin, created_at',
            ),
        _supabase.from('guru').select('guru_id, nama, niy, guru_jenis'),
      ]);

      final guruRows = List<Map<String, dynamic>>.from(results[2]);
      final guruById = <String, Map<String, dynamic>>{
        for (final guru in guruRows) guru['guru_id'].toString(): guru,
      };

      final combined = <Map<String, dynamic>>[];

      for (final row in List<Map<String, dynamic>>.from(results[0])) {
        final guru = guruById[row['guru_id']?.toString()];
        combined.add({
          ...row,
          'tipe_pengajuan': 'Izin',
          'nama_guru': guru?['nama'] ?? 'Guru tidak ditemukan',
          'niy_guru': guru?['niy']?.toString() ?? '-',
          'guru_jenis': guru?['guru_jenis'] ?? '-',
          'judul_jenis': (row['kategori'] ?? row['jenis'] ?? 'Izin').toString(),
          'tanggal_tampilan':
              '${row['tanggal_mulai'] ?? '-'} s.d. ${row['tanggal_selesai'] ?? '-'}',
          'keterangan_tampilan': row['alasan'] ?? '-',
        });
      }

      for (final row in List<Map<String, dynamic>>.from(results[1])) {
        final guru = guruById[row['guru_id']?.toString()];
        combined.add({
          ...row,
          'tipe_pengajuan': 'Sakit',
          'nama_guru': guru?['nama'] ?? 'Guru tidak ditemukan',
          'niy_guru': guru?['niy']?.toString() ?? '-',
          'guru_jenis': guru?['guru_jenis'] ?? '-',
          'judul_jenis': 'Sakit',
          'tanggal_tampilan': row['tanggal_sakit']?.toString() ?? '-',
          'keterangan_tampilan':
              'Diagnosa: ${row['diagnosa'] ?? '-'}\n'
              'Perawatan: ${row['status_perawatan'] ?? '-'}',
        });
      }

      combined.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(2000);
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(2000);
        return bDate.compareTo(aDate);
      });

      if (!mounted) return;
      setState(() {
        _requests = combined;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    return _requests.where((item) {
      final type = item['tipe_pengajuan'].toString();
      final status = (item['status'] ?? 'Menunggu').toString();
      final name = item['nama_guru'].toString().toLowerCase();
      final niy = item['niy_guru'].toString().toLowerCase();

      final filterMatch = _filter == 'Semua' ||
          (_filter == 'Izin' && type == 'Izin') ||
          (_filter == 'Sakit' && type == 'Sakit') ||
          (_filter == 'Menunggu' && status == 'Menunggu') ||
          (_filter == 'Disetujui' && status == 'Disetujui') ||
          (_filter == 'Ditolak' && status == 'Ditolak');

      return filterMatch && (name.contains(_search) || niy.contains(_search));
    }).toList();
  }

  int _countStatus(String status) => _requests
      .where((item) => (item['status'] ?? 'Menunggu') == status)
      .length;

  Color _statusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return _green;
      case 'Ditolak':
        return const Color(0xFFD64545);
      default:
        return const Color(0xFFD18A16);
    }
  }

  Future<void> _openDocument(Map<String, dynamic> item) async {
    final storedPath = item['lampiran_url']?.toString().trim() ?? '';
    if (storedPath.isEmpty) {
      _showMessage('Dokumen lampiran tidak tersedia.');
      return;
    }

    try {
      final path = _extractStoragePath(storedPath);
      final signedUrl = await _supabase.storage
          .from('dokumen-pengajuan')
          .createSignedUrl(path, 3600);
      final uri = Uri.parse(signedUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        _showMessage('Dokumen tidak dapat dibuka. Periksa aplikasi pembuka File.');
      }
    } catch (e) {
      _showMessage('Gagal membuka dokumen: $e');
    }
  }

  String _extractStoragePath(String value) {
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      return value.startsWith('/') ? value.substring(1) : value;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return value;
    const marker = '/dokumen-pengajuan/';
    final index = uri.path.indexOf(marker);
    if (index >= 0) {
      return Uri.decodeComponent(uri.path.substring(index + marker.length));
    }
    return value;
  }

  Future<void> _updateRequest(
    Map<String, dynamic> item,
    String newStatus,
    String note,
  ) async {
    final table = item['tipe_pengajuan'] == 'Izin'
        ? 'pengajuan_izin'
        : 'pengajuan_sakit';

    try {
      await _supabase.from(table).update({
        'status': newStatus,
        'catatan_admin': note.trim().isEmpty ? null : note.trim(),
      }).eq('pengajuan_id', item['pengajuan_id']);

      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage(
        newStatus == 'Disetujui'
            ? 'Pengajuan berhasil disetujui.'
            : 'Pengajuan berhasil ditolak.',
      );
      await _loadRequests();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal memperbarui pengajuan: $e');
      rethrow;
    }
  }

  Future<void> _showReviewDialog(Map<String, dynamic> item) async {
    final currentStatus = (item['status'] ?? 'Menunggu').toString();
    if (currentStatus != 'Menunggu') {
      _showDetailDialog(item);
      return;
    }

    final noteController = TextEditingController();
    bool saving = false;
    String? validationMessage;
    final isSick = item['tipe_pengajuan'] == 'Sakit';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 22,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dibuat sama dengan modal Detail Pengajuan.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 17, 16, 17),
                  decoration: const BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSick
                              ? Icons.medical_services_outlined
                              : Icons.event_note_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tinjau Pengajuan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Periksa informasi sebelum memberi keputusan',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: saving
                            ? null
                            : () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['nama_guru'].toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF26352E),
                                ),
                              ),
                            ),
                            _statusPill('Menunggu'),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'NIY: ${item['niy_guru']} • ${item['guru_jenis']}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF89928D),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(
                            height: 1,
                            color: Color(0xFFEDF0EE),
                          ),
                        ),
                        _detailInfoRow(
                          Icons.category_outlined,
                          'Jenis Pengajuan',
                          '${item['tipe_pengajuan']} • ${item['judul_jenis']}',
                        ),
                        _detailInfoRow(
                          Icons.calendar_month_outlined,
                          'Tanggal Pengajuan',
                          item['tanggal_tampilan'].toString(),
                        ),
                        _detailInfoRow(
                          isSick
                              ? Icons.medical_information_outlined
                              : Icons.notes,
                          isSick ? 'Keterangan Sakit' : 'Alasan Pengajuan',
                          item['keterangan_tampilan'].toString(),
                        ),
                        if ((item['delegasi'] ?? '').toString().trim().isNotEmpty)
                          _detailInfoRow(
                            Icons.person_outline,
                            'Delegasi',
                            item['delegasi'].toString(),
                          ),

                        // Lampiran tetap dapat dibuka sebelum keputusan dibuat.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5EEE8),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf_rounded,
                                color: _green,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dokumen Lampiran',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF26352E),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Periksa dokumen pengajuan',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF89928D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _openDocument(item),
                                style: TextButton.styleFrom(
                                  foregroundColor: _green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Buka File',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Text(
                          'Catatan Admin (Opsional)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF26352E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: noteController,
                          enabled: !saving,
                          minLines: 3,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Tuliskan catatan untuk guru...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9AA19D),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFBFA),
                            contentPadding: const EdgeInsets.all(13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE1E8E3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE1E8E3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _green,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        if (validationMessage != null) ...[
                          const SizedBox(height: 9),
                          Text(
                            validationMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Tombol keputusan dipisahkan di footer agar konsisten
                // dengan modal detail dan tetap mudah digunakan di layar HP.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 5, 16, 17),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF69736D),
                            side: const BorderSide(
                              color: Color(0xFFDDE3DF),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  setDialogState(() {
                                    saving = true;
                                    validationMessage = null;
                                  });
                                  try {
                                    await _updateRequest(
                                      item,
                                      'Ditolak',
                                      noteController.text,
                                    );
                                  } catch (_) {
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        saving = false;
                                        validationMessage =
                                            'Gagal menyimpan keputusan. Coba lagi.';
                                      });
                                    }
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD64545),
                            side: const BorderSide(
                              color: Color(0xFFD64545),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text(
                            'Tolak',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  setDialogState(() {
                                    saving = true;
                                    validationMessage = null;
                                  });
                                  try {
                                    await _updateRequest(
                                      item,
                                      'Disetujui',
                                      noteController.text,
                                    );
                                  } catch (_) {
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        saving = false;
                                        validationMessage =
                                            'Gagal menyimpan keputusan. Coba lagi.';
                                      });
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Setujui',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    noteController.dispose();
  }

  Widget _detailInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _green, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A9290),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFF26352E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'Disetujui'
                ? Icons.check_circle
                : status == 'Ditolak'
                    ? Icons.cancel
                    : Icons.schedule,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> item) {
    final isSick = item['tipe_pengajuan'] == 'Sakit';
    final status = (item['status'] ?? 'Menunggu').toString();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                decoration: const BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSick
                            ? Icons.medical_services_outlined
                            : Icons.event_note_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Pengajuan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Informasi permohonan guru',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['nama_guru'].toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF26352E),
                              ),
                            ),
                          ),
                          _statusPill(status),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'NIY: ${item['niy_guru']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF89928D),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Color(0xFFEDF0EE)),
                      ),
                      _detailInfoRow(
                        Icons.category_outlined,
                        'Jenis Pengajuan',
                        '${item['tipe_pengajuan']} • ${item['judul_jenis']}',
                      ),
                      _detailInfoRow(
                        Icons.calendar_month_outlined,
                        'Tanggal Pengajuan',
                        item['tanggal_tampilan'].toString(),
                      ),
                      _detailInfoRow(
                        isSick ? Icons.medical_information_outlined : Icons.notes,
                        isSick ? 'Keterangan Sakit' : 'Alasan Pengajuan',
                        item['keterangan_tampilan'].toString(),
                      ),
                      if ((item['delegasi'] ?? '').toString().trim().isNotEmpty)
                        _detailInfoRow(
                          Icons.person_outline,
                          'Delegasi',
                          item['delegasi'].toString(),
                        ),
                      if ((item['catatan_admin'] ?? '').toString().trim().isNotEmpty)
                        _detailInfoRow(
                          Icons.comment_outlined,
                          'Catatan Admin',
                          item['catatan_admin'].toString(),
                        ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5EEE8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: _green,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dokumen Lampiran',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF26352E),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Buka file pengajuan',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF89928D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _openDocument(item),
                              style: TextButton.styleFrom(
                                foregroundColor: _green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Buka File',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _summaryCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7EAED)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color, size: 14),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF777777),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _filter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = label),
        selectedColor: _green,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF666666),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: selected ? _green : const Color(0xFFE0E3E7),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'Menunggu').toString();
    final color = _statusColor(status);
    final isPending = status == 'Menunggu';
    final isSick = item['tipe_pengajuan'] == 'Sakit';

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: isSick
                    ? const Color(0xFFE5F1FB)
                    : const Color(0xFFECEAFF),
                child: Icon(
                  isSick ? Icons.medical_services_outlined : Icons.event_note,
                  color: isSick ? const Color(0xFF2878B8) : _purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nama_guru'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'NIY: ${item['niy_guru']} • ${item['guru_jenis']}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF858585),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['tipe_pengajuan']} • ${item['judul_jenis']}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Tanggal: ${item['tanggal_tampilan']}',
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  item['keterangan_tampilan'].toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDetailDialog(item),
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: const Text('Detail', style: TextStyle(fontSize: 10)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: const BorderSide(color: _green),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDocument(item),
                  icon: const Icon(Icons.picture_as_pdf, size: 15),
                  label: const Text('Dokumen', style: TextStyle(fontSize: 10)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,
                    side: const BorderSide(color: _purple),
                  ),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 2),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showReviewDialog(item),
                icon: const Icon(Icons.fact_check_outlined, size: 16),
                label: const Text('Tinjau Pengajuan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filteredRequests;

    return Container(
      color: _background,
      child: RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Menunggu',
                    _countStatus('Menunggu'),
                    const Color(0xFFD18A16),
                    Icons.hourglass_top,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryCard(
                    'Disetujui',
                    _countStatus('Disetujui'),
                    _green,
                    Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryCard(
                    'Ditolak',
                    _countStatus('Ditolak'),
                    const Color(0xFFD64545),
                    Icons.cancel_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama guru atau NIY...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E3E7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E3E7)),
                ),
              ),
            ),
            const SizedBox(height: 13),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Semua'),
                  _filterChip('Izin'),
                  _filterChip('Sakit'),
                  _filterChip('Menunggu'),
                  _filterChip('Disetujui'),
                  _filterChip('Ditolak'),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Pengajuan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F454B),
                  ),
                ),
                Text(
                  '${visible.length} pengajuan',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(36),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    const Text('Gagal memuat pengajuan.'),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: _loadRequests,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              )
            else if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: Text('Belum ada pengajuan pada filter ini.')),
              )
            else
              ...visible.map(_requestCard),
          ],
        ),
      ),
    );
  }
}
