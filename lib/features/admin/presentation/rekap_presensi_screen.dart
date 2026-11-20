import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RekapPresensiScreen extends StatefulWidget {
  const RekapPresensiScreen({super.key});

  @override
  State<RekapPresensiScreen> createState() => _RekapPresensiScreenState();
}

class _RekapPresensiScreenState extends State<RekapPresensiScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  static const Color _green = Color(0xFF43816B);
  static const Color _purple = Color(0xFF6557D9);
  static const Color _background = Color(0xFFF5F7F8);

  bool _isRekapMingguan = true;
  bool _isLoading = true;
  bool _isExporting = false;
  int _weekIndex = 0;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _search = '';

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _attendanceRows = [];
  List<Map<String, dynamic>> _leaveRows = [];
  List<Map<String, dynamic>> _sickRows = [];
  List<int> _holidays = [4];
  final Map<String, Future<String?>> _photoUrlCache = {};

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
    _loadReport();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _daysInMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

  int get _weekCount => (_daysInMonth + 6) ~/ 7;

  DateTime get _periodStart {
    if (!_isRekapMingguan) {
      return DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    }
    return DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1 + (_weekIndex * 7),
    );
  }

  DateTime get _periodEnd {
    if (!_isRekapMingguan) {
      return DateTime(_selectedMonth.year, _selectedMonth.month, _daysInMonth);
    }
    final lastDay = (1 + (_weekIndex * 7) + 6).clamp(1, _daysInMonth);
    return DateTime(_selectedMonth.year, _selectedMonth.month, lastDay);
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _formatShortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_monthNames[date.month - 1]} ${date.year}';

  String get _periodLabel => _isRekapMingguan
      ? 'Minggu Ke-${_weekIndex + 1}'
      : '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

  String get _periodRange =>
      '${_formatShortDate(_periodStart)} - ${_formatShortDate(_periodEnd)}';

  Future<void> _loadReport() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final start = _dateKey(_periodStart);
      final end = _dateKey(_periodEnd);

      // Query dipisah agar tipe hasil Supabase tidak berubah menjadi Object?.
      final teachersResult = await _supabase
          .from('guru')
          .select('guru_id, nama, niy, guru_jenis, status, foto_url')
          .order('nama');

      final attendanceResult = await _supabase
          .from('presensi')
          .select('guru_id, tanggal, status')
          .gte('tanggal', start)
          .lte('tanggal', end);

      final leaveResult = await _supabase
          .from('pengajuan_izin')
          .select('guru_id, tanggal_mulai, tanggal_selesai, status')
          .eq('status', 'Disetujui')
          .lte('tanggal_mulai', end)
          .gte('tanggal_selesai', start);

      final sickResult = await _supabase
          .from('pengajuan_sakit')
          .select('guru_id, tanggal_sakit, status')
          .eq('status', 'Disetujui')
          .gte('tanggal_sakit', start)
          .lte('tanggal_sakit', end);

      final schedule = await _supabase
          .from('jadwal')
          .select('hari_libur')
          .limit(1)
          .maybeSingle();
      final rawHolidays = schedule?['hari_libur'];
      final holidays = rawHolidays is List
          ? rawHolidays.map((value) => int.tryParse(value.toString()))
              .whereType<int>().toList()
          : <int>[4];

      if (!mounted) return;
      setState(() {
        _teachers = List<Map<String, dynamic>>.from(teachersResult);
        _attendanceRows = List<Map<String, dynamic>>.from(attendanceResult);
        _leaveRows = List<Map<String, dynamic>>.from(leaveResult);
        _sickRows = List<Map<String, dynamic>>.from(sickResult);
        _holidays = holidays;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat rekap presensi: $e')),
      );
    }
  }

  void _changeMode(bool weekly) {
    setState(() {
      _isRekapMingguan = weekly;
      _weekIndex = 0;
    });
    _loadReport();
  }

  void _movePeriod(int direction) {
    setState(() {
      if (_isRekapMingguan) {
        final next = _weekIndex + direction;
        if (next >= 0 && next < _weekCount) _weekIndex = next;
      } else {
        _selectedMonth = DateTime(
          _selectedMonth.year,
          _selectedMonth.month + direction,
        );
        if (_weekIndex >= _weekCount) _weekIndex = _weekCount - 1;
      }
    });
    _loadReport();
  }

  List<DateTime> _workingDays() {
    final days = <DateTime>[];
    for (var date = _periodStart;
        !date.isAfter(_periodEnd);
        date = date.add(const Duration(days: 1))) {
      final dayCode = date.weekday % 7; // Minggu=0, Senin=1, ... Sabtu=6
      if (!_holidays.contains(dayCode)) days.add(date);
    }
    return days;
  }

  Set<String> _approvedLeaveDates(String guruId, Set<String> workingKeys) {
    final dates = <String>{};
    for (final row in _leaveRows) {
      if (row['guru_id']?.toString() != guruId) continue;
      final from = DateTime.tryParse(row['tanggal_mulai']?.toString() ?? '');
      final to = DateTime.tryParse(row['tanggal_selesai']?.toString() ?? '');
      if (from == null || to == null) continue;
      for (var date = DateTime(from.year, from.month, from.day);
          !date.isAfter(DateTime(to.year, to.month, to.day));
          date = date.add(const Duration(days: 1))) {
        final key = _dateKey(date);
        if (workingKeys.contains(key)) dates.add(key);
      }
    }
    return dates;
  }

  Set<String> _approvedSickDates(String guruId, Set<String> workingKeys) {
    return _sickRows
        .where((row) => row['guru_id']?.toString() == guruId)
        .map((row) => row['tanggal_sakit']?.toString() ?? '')
        .where((date) => workingKeys.contains(date))
        .toSet();
  }

  Map<String, dynamic> _calculateTeacher(Map<String, dynamic> teacher) {
    final guruId = teacher['guru_id'].toString();
    final workingDays = _workingDays();
    final workingKeys = workingDays.map(_dateKey).toSet();

    final attendanceDates = _attendanceRows
        .where((row) => row['guru_id']?.toString() == guruId)
        .map((row) => row['tanggal']?.toString() ?? '')
        .where((date) => workingKeys.contains(date))
        .toSet();

    final leaveDates = _approvedLeaveDates(guruId, workingKeys);
    final sickDates = _approvedSickDates(guruId, workingKeys);

    // Jika ada tanggal tumpang tindih, prioritas: Hadir, lalu Sakit, lalu Izin.
    final present = attendanceDates.length;
    final sick = sickDates.difference(attendanceDates).length;
    final leave = leaveDates.difference(attendanceDates).difference(sickDates).length;
    final expected = workingKeys.length;
    final unexcused = (expected - present - sick - leave).clamp(0, expected);
    final eligible = (expected - sick - leave).clamp(0, expected);

    double percent(int value, int total) =>
        total == 0 ? 0 : (value / total) * 100;

    return {
      ...teacher,
      'hadir_count': present,
      'izin_count': leave,
      'sakit_count': sick,
      'alpa_count': unexcused,
      'hari_kerja': expected,
      'hari_dinilai': eligible,
      'hadir_percent': percent(present, eligible),
      'izin_percent': percent(leave, expected),
      'sakit_percent': percent(sick, expected),
    };
  }

  List<Map<String, dynamic>> get _reportRows {
    final rows = _teachers.map(_calculateTeacher).toList();
    rows.sort((a, b) => (a['nama'] ?? '')
        .toString().compareTo((b['nama'] ?? '').toString()));
    return rows;
  }

  List<Map<String, dynamic>> get _visibleRows => _reportRows.where((row) {
        final name = (row['nama'] ?? '').toString().toLowerCase();
        final niy = (row['niy'] ?? '').toString().toLowerCase();
        return name.contains(_search) || niy.contains(_search);
      }).toList();

  int get _totalPresent =>
      _reportRows.fold(0, (sum, row) => sum + (row['hadir_count'] as int));
  int get _totalLeave =>
      _reportRows.fold(0, (sum, row) => sum + (row['izin_count'] as int));
  int get _totalSick =>
      _reportRows.fold(0, (sum, row) => sum + (row['sakit_count'] as int));
  int get _totalExpected =>
      _reportRows.fold(0, (sum, row) => sum + (row['hari_dinilai'] as int));
  int get _totalAlpa =>
      _reportRows.fold(0, (sum, row) => sum + (row['alpa_count'] as int));

  double _percent(int count, int total) =>
      total == 0 ? 0 : count / total * 100;

  Future<void> _exportExcel() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Rekap Presensi'];
      sheet.appendRow([
        xl.TextCellValue('REKAP PRESENSI GURU'),
      ]);
      sheet.appendRow([
        xl.TextCellValue('Periode'),
        xl.TextCellValue(_periodLabel),
      ]);
      sheet.appendRow([
        xl.TextCellValue('Rentang Tanggal'),
        xl.TextCellValue(_periodRange),
      ]);
      sheet.appendRow([
        xl.TextCellValue('Nama Guru'),
        xl.TextCellValue('NIY'),
        xl.TextCellValue('Jenis Guru'),
        xl.TextCellValue('Hari Kerja'),
        xl.TextCellValue('Hadir'),
        xl.TextCellValue('Izin Disetujui'),
        xl.TextCellValue('Sakit Disetujui'),
        xl.TextCellValue('Tidak Hadir'),
        xl.TextCellValue('Persentase Kehadiran'),
      ]);

      for (final row in _reportRows) {
        sheet.appendRow([
          xl.TextCellValue((row['nama'] ?? '-').toString()),
          xl.TextCellValue((row['niy'] ?? '-').toString()),
          xl.TextCellValue((row['guru_jenis'] ?? '-').toString()),
          xl.IntCellValue(row['hari_kerja'] as int),
          xl.IntCellValue(row['hadir_count'] as int),
          xl.IntCellValue(row['izin_count'] as int),
          xl.IntCellValue(row['sakit_count'] as int),
          xl.IntCellValue(row['alpa_count'] as int),
          xl.TextCellValue(
            '${(row['hadir_percent'] as double).toStringAsFixed(1)}%',
          ),
        ]);
      }

      sheet.appendRow([]);
      sheet.appendRow([
        xl.TextCellValue('TOTAL'),
        xl.TextCellValue(''),
        xl.TextCellValue(''),
        xl.IntCellValue(_reportRows.fold(
            0, (sum, row) => sum + (row['hari_kerja'] as int))),
        xl.IntCellValue(_totalPresent),
        xl.IntCellValue(_totalLeave),
        xl.IntCellValue(_totalSick),
        xl.IntCellValue(_totalAlpa),
        xl.TextCellValue(
          '${_percent(_totalPresent, _totalExpected).toStringAsFixed(1)}%',
        ),
      ]);

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Gagal membuat file Excel.');

      final directory = await getTemporaryDirectory();
      final fileName = 'Rekap_Presensi_${_dateKey(_periodStart)}_'
          '${_dateKey(_periodEnd)}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Rekap Presensi $_periodLabel ($_periodRange)',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor Excel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF2EB47D),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            _tabItem(
              label: 'Rekap Perminggu',
              icon: Icons.list_alt,
              active: _isRekapMingguan,
              onTap: () => _changeMode(true),
            ),
            _tabItem(
              label: 'Rekap Perbulan',
              icon: Icons.calendar_month,
              active: !_isRekapMingguan,
              onTap: () => _changeMode(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabItem({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? _purple : Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active ? _purple : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodNavigator() {
    final canGoLeft = _isRekapMingguan
        ? _weekIndex > 0 || _selectedMonth.year > 2024 ||
            _selectedMonth.month > 1
        : _selectedMonth.year > 2024 || _selectedMonth.month > 1;
    final canGoRight = _isRekapMingguan
        ? _weekIndex < _weekCount - 1 ||
            _selectedMonth.year < DateTime.now().year ||
            (_selectedMonth.year == DateTime.now().year &&
                _selectedMonth.month < DateTime.now().month)
        : _selectedMonth.isBefore(
            DateTime(DateTime.now().year, DateTime.now().month));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E3E7)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navButton(Icons.chevron_left, canGoLeft, () {
              if (_isRekapMingguan && _weekIndex > 0) {
                _movePeriod(-1);
              } else {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                  );
                  _weekIndex = _weekCount - 1;
                });
                _loadReport();
              }
            }),
            Column(
              children: [
                Text(
                  _periodLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF252525),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _periodRange,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF858585)),
                ),
              ],
            ),
            _navButton(Icons.chevron_right, canGoRight, () {
              if (_isRekapMingguan && _weekIndex < _weekCount - 1) {
                _movePeriod(1);
              } else if (_isRekapMingguan) {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                  );
                  _weekIndex = 0;
                });
                _loadReport();
              } else {
                _movePeriod(1);
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E3E7)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 19,
          color: enabled ? _purple : const Color(0xFFB8BEC6),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String desc,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E3E7), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
            fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF858585))),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: const Color(0xFFF0F1F3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(
            fontSize: 8, color: Color(0xFF858585))),
        ],
      ),
    );
  }

  Widget _buildOverallStatistics() {
    final attendancePercent = _percent(_totalPresent, _totalExpected);
    final scheduledSlots = _reportRows.fold<int>(
      0, (sum, row) => sum + (row['hari_kerja'] as int));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              label: '% KEHADIRAN',
              value: '${attendancePercent.toStringAsFixed(1)}%',
              desc: '$_totalPresent kehadiran',
              color: const Color(0xFF16A875),
              progress: attendancePercent / 100,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              label: '% IZIN',
              value: '${_percent(_totalLeave, scheduledSlots).toStringAsFixed(1)}%',
              desc: '$_totalLeave hari izin',
              color: const Color(0xFFF59E0B),
              progress: _percent(_totalLeave, scheduledSlots) / 100,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              label: '% SAKIT',
              value: '${_percent(_totalSick, scheduledSlots).toStringAsFixed(1)}%',
              desc: '$_totalSick hari sakit',
              color: const Color(0xFFEF4444),
              progress: _percent(_totalSick, scheduledSlots) / 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        border: Border.all(color: const Color(0xFFE0E3E7)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF858585))),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Future<String?> _getTeacherPhotoUrl(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    if (value.isEmpty) return Future.value(null);

    return _photoUrlCache.putIfAbsent(value, () async {
      try {
        // Jika tersimpan sebagai URL publik, gunakan langsung.
        final uri = Uri.tryParse(value);
        if (uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https')) {
          if (uri.path.contains('/object/public/foto-guru/')) {
            return value;
          }

          // URL signed lama: ambil path dan buat signed URL baru.
          const marker = '/object/sign/foto-guru/';
          final index = uri.path.indexOf(marker);
          if (index >= 0) {
            final path = Uri.decodeComponent(
              uri.path.substring(index + marker.length),
            );
            final cleanPath = path.split('?').first;
            return await _supabase.storage
                .from('foto-guru')
                .createSignedUrl(cleanPath, 3600);
          }
        }

        // Selain URL, anggap nilai sebagai path di bucket foto-guru.
        final path = value.startsWith('/') ? value.substring(1) : value;
        return await _supabase.storage
            .from('foto-guru')
            .createSignedUrl(path, 3600);
      } catch (e) {
        debugPrint('Gagal memuat foto guru ($value): $e');
        return null;
      }
    });
  }

  Widget _teacherCard(Map<String, dynamic> row) {
    final name = (row['nama'] ?? '-').toString();
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((part) => part[0]).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB7E5C7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String?>(
                future: _getTeacherPhotoUrl(row['foto_url']?.toString()),
                builder: (context, snapshot) {
                  final photoUrl = snapshot.data;
                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFEAE8FF),
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _purple,
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
                    Text(name, style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: Color(0xFF252525))),
                    const SizedBox(height: 4),
                    Text(
                      '${row['guru_jenis'] ?? 'Guru'} • NIY: ${row['niy'] ?? '-'}',
                      style: const TextStyle(fontSize: 9, color: Color(0xFF858585)),
                    ),
                  ],
                ),
              ),
              Text(
                '${(row['hadir_percent'] as double).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: _green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE7EAED)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statBox('Hadir', '${row['hadir_count']} (${(row['hadir_percent'] as double).toStringAsFixed(0)}%)', const Color(0xFF16A875))),
              const SizedBox(width: 7),
              Expanded(child: _statBox('Izin', '${row['izin_count']} (${(row['izin_percent'] as double).toStringAsFixed(0)}%)', const Color(0xFFF59E0B))),
              const SizedBox(width: 7),
              Expanded(child: _statBox('Sakit', '${row['sakit_count']} (${(row['sakit_percent'] as double).toStringAsFixed(0)}%)', const Color(0xFF858585))),
            ],
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Tidak hadir: ${row['alpa_count']} hari',
              style: const TextStyle(fontSize: 9, color: Color(0xFF858585)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: _isExporting || _isLoading ? null : _exportExcel,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor: Colors.grey.shade400,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isExporting)
              const SizedBox(
                width: 17, height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              _isExporting ? 'Menyiapkan Excel...' : 'Download Rekapan (Excel)',
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visibleRows;
    return Container(
      color: _background,
      child: RefreshIndicator(
        onRefresh: _loadReport,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildTabs(),
            const SizedBox(height: 16),
            _buildPeriodNavigator(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(45),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildOverallStatistics(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama guru atau NIY...',
                    prefixIcon: const Icon(Icons.search, size: 19),
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detail Persentase per Guru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF252525),
                      ),
                    ),
                    Text(
                      '${rows.length} Guru',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF858585),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: Text('Data guru tidak ditemukan.')),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: rows.map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _teacherCard(row),
                    )).toList(),
                  ),
                ),
              const SizedBox(height: 8),
              _buildDownloadButton(),
            ],
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
