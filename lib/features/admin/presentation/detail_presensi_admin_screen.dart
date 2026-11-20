import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPresensiAdminScreen extends StatefulWidget {
  const DetailPresensiAdminScreen({super.key});

  @override
  State<DetailPresensiAdminScreen> createState() =>
      _DetailPresensiAdminScreenState();
}

class _DetailPresensiAdminScreenState extends State<DetailPresensiAdminScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String _searchQuery = '';
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _approvedLeave = [];
  List<Map<String, dynamic>> _approvedSick = [];

  static const Color _green = Color(0xFF43816B);
  static const Color _purple = Color(0xFF6557D9);
  static const Color _background = Color(0xFFF6F7F9);

  @override
  void initState() {
    super.initState();
    _loadDailyAttendance();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _formatDate(DateTime date) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${days[date.weekday - 1]}, ${date.day} '
        '${months[date.month - 1]} ${date.year}';
  }

  // Mendukung path Storage maupun URL Supabase yang sudah tersimpan.
  String _extractStoragePath(String value, String bucket) {
    final input = value.trim();
    if (input.isEmpty) return '';

    if (!input.startsWith('http://') && !input.startsWith('https://')) {
      return input.startsWith('/') ? input.substring(1) : input;
    }

    final uri = Uri.tryParse(input);
    if (uri == null) return input;

    final marker = '/$bucket/';
    final fullPath = uri.path;
    final markerIndex = fullPath.indexOf(marker);
    if (markerIndex >= 0) {
      return Uri.decodeComponent(fullPath.substring(markerIndex + marker.length));
    }

    return input;
  }

  Future<String?> _createImageUrl(String? storedValue, String bucket) async {
    if (storedValue == null || storedValue.trim().isEmpty) return null;

    final path = _extractStoragePath(storedValue, bucket);
    if (path.isEmpty) return null;

    try {
      // Jika yang tersimpan URL lengkap, gunakan URL tersebut.
      if (storedValue.startsWith('https://') ||
          storedValue.startsWith('http://')) {
        final uri = Uri.tryParse(storedValue);
        if (uri != null &&
            (uri.path.contains('/object/sign/') ||
                uri.path.contains('/object/public/'))) {
          return storedValue;
        }
      }
      return await _supabase.storage.from(bucket).createSignedUrl(path, 3600);
    } catch (e) {
      debugPrint('Gagal membuat signed URL bucket $bucket: $e');
      return null;
    }
  }

  Future<void> _loadDailyAttendance() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final date = _dateKey(_selectedDate);
      final results = await Future.wait([
        _supabase
            .from('guru')
            .select('guru_id, nama, niy, guru_jenis, status, foto_url')
            .order('nama'),
        _supabase
            .from('presensi')
            .select(
              'presensi_id, guru_id, tanggal, jam, status, foto_bukti, '
              'latitude, longitude, validasi_gps, waktu_presensi',
            )
            .eq('tanggal', date),
        _supabase
            .from('pengajuan_izin')
            .select('guru_id, tanggal_mulai, tanggal_selesai, status, jenis, kategori')
            .eq('status', 'Disetujui')
            .lte('tanggal_mulai', date)
            .gte('tanggal_selesai', date),
        _supabase
            .from('pengajuan_sakit')
            .select('guru_id, tanggal_sakit, status, status_perawatan')
            .eq('status', 'Disetujui')
            .eq('tanggal_sakit', date),
      ]);

      if (!mounted) return;
      setState(() {
        _teachers = List<Map<String, dynamic>>.from(results[0]);
        _attendance = List<Map<String, dynamic>>.from(results[1]);
        _approvedLeave = List<Map<String, dynamic>>.from(results[2]);
        _approvedSick = List<Map<String, dynamic>>.from(results[3]);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data presensi: $e')),
      );
    }
  }

  Map<String, dynamic>? _findByGuru(
    List<Map<String, dynamic>> rows,
    String guruId,
  ) {
    for (final row in rows) {
      if (row['guru_id']?.toString() == guruId) return row;
    }
    return null;
  }

  String _statusFor(Map<String, dynamic> teacher) {
    final id = teacher['guru_id'].toString();
    if (_findByGuru(_attendance, id) != null) return 'Hadir';
    if (_findByGuru(_approvedSick, id) != null) return 'Sakit';
    if (_findByGuru(_approvedLeave, id) != null) return 'Izin';
    return 'Belum Presensi';
  }

  List<Map<String, dynamic>> get _filteredTeachers {
    return _teachers.where((teacher) {
      final name = (teacher['nama'] ?? '').toString().toLowerCase();
      final niy = (teacher['niy'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || niy.contains(_searchQuery);
    }).toList();
  }

  int get _presentCount =>
      _teachers.where((teacher) => _statusFor(teacher) == 'Hadir').length;
  int get _leaveCount =>
      _teachers.where((teacher) => _statusFor(teacher) == 'Izin').length;
  int get _sickCount =>
      _teachers.where((teacher) => _statusFor(teacher) == 'Sakit').length;
  int get _notPresentCount =>
      _teachers.where((teacher) => _statusFor(teacher) == 'Belum Presensi').length;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadDailyAttendance();
    }
  }

  Future<void> _showAttendanceDetail(
    Map<String, dynamic> teacher,
    Map<String, dynamic> attendance,
  ) async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    final results = await Future.wait([
      _createImageUrl(teacher['foto_url']?.toString(), 'foto-guru'),
      _createImageUrl(attendance['foto_bukti']?.toString(), 'bukti-presensi'),
    ]);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final profileUrl = results[0];
    final proofUrl = results[1];
    final status = (attendance['status'] ?? 'Hadir').toString();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430, maxHeight: 680),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                  decoration: const BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Detail Presensi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 31,
                              backgroundColor: const Color(0xFFECEAFF),
                              backgroundImage: profileUrl != null
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: profileUrl == null
                                  ? const Icon(Icons.person, color: _purple, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    teacher['nama']?.toString() ?? '-',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF252525),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'NIY: ${teacher['niy'] ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF777777),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  _statusChip(status, _green),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _sectionTitle('Bukti Foto Presensi'),
                        const SizedBox(height: 9),
                        if (proofUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.network(
                              proofUrl,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const SizedBox(
                                  height: 220,
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (_, __, ___) => _photoPlaceholder(
                                'Foto gagal dimuat. Periksa path dan izin Storage.',
                              ),
                            ),
                          )
                        else
                          _photoPlaceholder(
                            'Foto bukti tidak tersedia. Path: '
                            '${attendance['foto_bukti'] ?? 'kosong'}',
                          ),
                        const SizedBox(height: 18),
                        _sectionTitle('Informasi Presensi'),
                        const SizedBox(height: 8),
                        _infoCard([
                          _infoRow(Icons.calendar_today, 'Tanggal', _formatDate(_selectedDate)),
                          _infoRow(Icons.access_time, 'Waktu', attendance['jam']?.toString() ?? '-'),
                          _infoRow(
                            Icons.verified_outlined,
                            'Validasi GPS',
                            attendance['validasi_gps'] == true ? 'Valid' : 'Tidak valid / tidak tersedia',
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _sectionTitle('Lokasi Presensi'),
                        const SizedBox(height: 8),
                        _infoCard([
                          _infoRow(Icons.location_on_outlined, 'Latitude', attendance['latitude']?.toString() ?? '-'),
                          _infoRow(Icons.explore_outlined, 'Longitude', attendance['longitude']?.toString() ?? '-'),
                        ]),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF303030),
        ),
      );

  Widget _photoPlaceholder(String message) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported_outlined, size: 34, color: Colors.grey),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EAED)),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _green),
          const SizedBox(width: 9),
          SizedBox(
            width: 95,
            child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Hadir':
        return _green;
      case 'Izin':
        return _purple;
      case 'Sakit':
        return const Color(0xFF2878B8);
      default:
        return const Color(0xFFD97706);
    }
  }

  Widget _summaryCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8EAED)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 7),
            Text(
              '$count',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF777777))),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    final status = _statusFor(teacher);
    final guruId = teacher['guru_id'].toString();
    final attendance = _findByGuru(_attendance, guruId);
    final color = _statusColor(status);
    final profileValue = teacher['foto_url']?.toString();
    final profilePath = profileValue == null
        ? ''
        : _extractStoragePath(profileValue, 'foto-guru');
    final profileUrlFuture = profilePath.isEmpty
        ? null
        : _createImageUrl(profileValue, 'foto-guru');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8EAED)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          FutureBuilder<String?>(
            future: profileUrlFuture,
            builder: (context, snapshot) {
              final url = snapshot.data;
              return CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE9E7FF),
                backgroundImage: url != null ? NetworkImage(url) : null,
                child: url == null
                    ? Text(
                        (teacher['nama']?.toString().trim().isNotEmpty ?? false)
                            ? teacher['nama'].toString().trim()[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: _purple,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher['nama']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF252525)),
                ),
                const SizedBox(height: 3),
                Text(
                  'NIY: ${teacher['niy'] ?? '-'}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF858585)),
                ),
                if (status == 'Hadir')
                  Text(
                    'Waktu: ${attendance?['jam'] ?? '-'}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusChip(status, color),
              if (attendance != null)
                TextButton(
                  onPressed: () => _showAttendanceDetail(teacher, attendance),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Detail', style: TextStyle(fontSize: 10)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tanggal Presensi',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
                    ),
                  ),
                  Flexible(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month, size: 15),
                      label: Text(
                        _formatDate(_selectedDate),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _purple,
                        side: const BorderSide(color: Color(0xFFE0E3E7)),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadDailyAttendance,
                    icon: const Icon(Icons.refresh, color: _green),
                    tooltip: 'Muat ulang',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _summaryCard('Hadir', _presentCount, _green, Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    _summaryCard('Belum presensi', _notPresentCount, const Color(0xFFD97706), Icons.access_time),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _summaryCard('Izin', _leaveCount, _purple, Icons.event_available),
                    const SizedBox(width: 8),
                    _summaryCard('Sakit', _sickCount, const Color(0xFF2878B8), Icons.medical_services_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama guru atau NIY...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(color: Color(0xFFE0E3E7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(color: Color(0xFFE0E3E7)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daftar Presensi Guru', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
                    Text('${_filteredTeachers.length} guru', style: const TextStyle(fontSize: 10, color: Color(0xFF858585))),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (_filteredTeachers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Data guru tidak ditemukan.')),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _filteredTeachers.map(_buildTeacherCard).toList(),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
