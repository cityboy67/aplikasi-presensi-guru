import 'package:flutter/material.dart';

/// Widget konten saja — tanpa Scaffold, AppBar, atau BottomNav.
/// Scaffold & navbar dihandle sepenuhnya oleh AdminDashboardScreen.
class RekapPresensiScreen extends StatefulWidget {
  const RekapPresensiScreen({super.key});

  @override
  State<RekapPresensiScreen> createState() => _RekapPresensiScreenState();
}

class _RekapPresensiScreenState extends State<RekapPresensiScreen> {
  bool _isRekapMingguan = true;
  int _weekIndex = 2; // default Minggu ke-3 (0-based)
  int _monthIndex = 8; // default September (0-based)

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _weekRanges = [
    '1 - 7 Sep 2026',
    '8 - 14 Sep 2026',
    '15 - 21 Sep 2026',
    '22 - 30 Sep 2026',
  ];

  final List<Map<String, String>> _guruList = List.generate(
    4,
    (index) => {
      'inisial': 'MB',
      'nama': 'Muhammad Budi, S.Pd.,\nM.Kom.',
      'keterangan': 'Guru TKJ • NIP. 19850312',
      'hadir': '96%',
      'izin': '4%',
      'sakit': '0%',
    },
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabs(),
          const SizedBox(height: 16),
          _buildPeriodNavigator(),
          const SizedBox(height: 16),
          _buildOverallStatistics(),
          const SizedBox(height: 24),
          _buildDetailSection(),
          const SizedBox(height: 24),
          _buildDownloadButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── TAB JENIS REKAP ──────────────────────────────────────────
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF2EB47D),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _tabItem(
              label: 'Rekap Perminggu',
              icon: Icons.list_alt,
              isActive: _isRekapMingguan,
              activeColor: const Color(0xFF6557D9),
              onTap: () => setState(() => _isRekapMingguan = true),
            ),
            _tabItem(
              label: 'Rekap Perbulan',
              icon: Icons.calendar_month,
              isActive: !_isRekapMingguan,
              activeColor: const Color(0xFF2EB47D),
              onTap: () => setState(() => _isRekapMingguan = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabItem({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? activeColor : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? activeColor : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── NAVIGASI PERIODE (slideable) ─────────────────────────────
  Widget _buildPeriodNavigator() {
    final isWeekly = _isRekapMingguan;
    final canGoLeft = isWeekly ? _weekIndex > 0 : _monthIndex > 0;
    final canGoRight = isWeekly ? _weekIndex < 3 : _monthIndex < 11;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E3E7)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Tombol kiri
            _navButton(
              Icons.chevron_left,
              enabled: canGoLeft,
              onTap: () => setState(() {
                if (isWeekly) {
                  if (_weekIndex > 0) _weekIndex--;
                } else {
                  if (_monthIndex > 0) _monthIndex--;
                }
              }),
            ),
            // Label tengah
            Column(
              children: [
                Text(
                  isWeekly
                      ? 'Minggu Ke-${_weekIndex + 1}'
                      : '${_monthNames[_monthIndex]} 2026',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF252525),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isWeekly
                      ? '${_weekRanges[_weekIndex]} • Semester Ganjil'
                      : 'Semester ${_monthIndex < 6 ? 'Genap' : 'Ganjil'} 2026',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    color: Color(0xFF858585),
                  ),
                ),
              ],
            ),
            // Tombol kanan
            _navButton(
              Icons.chevron_right,
              enabled: canGoRight,
              onTap: () => setState(() {
                if (isWeekly) {
                  if (_weekIndex < 3) _weekIndex++;
                } else {
                  if (_monthIndex < 11) _monthIndex++;
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(
    IconData icon, {
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E3E7)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF6557D9) : const Color(0xFFB8BEC6),
        ),
      ),
    );
  }

  // ── RINGKASAN STATISTIK ──────────────────────────────────────
  Widget _buildOverallStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              label: '% KEHADIRAN',
              value: '90%',
              desc: '46 Guru Hadir\nTeratur',
              valueColor: const Color(0xFF16C784),
              progress: 0.9,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              label: '% IZIN',
              value: '3%',
              desc: '2 Guru Izin',
              valueColor: const Color(0xFFF59E0B),
              progress: 0.03,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              label: '% SAKIT',
              value: '2%',
              desc: '1 Guru Sakit',
              valueColor: const Color(0xFFEF4444),
              progress: 0.02,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String desc,
    required Color valueColor,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E3E7), width: 0.5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: valueColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFF858585),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: valueColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 8,
              color: Color(0xFF858585),
            ),
          ),
        ],
      ),
    );
  }

  // ── DETAIL PER GURU ──────────────────────────────────────────
  Widget _buildDetailSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail Persentase per Guru',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF252525),
                ),
              ),
              const Text(
                '40 Guru',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Color(0xFF858585),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _guruList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _teacherCard(_guruList[index]),
          ),
        ],
      ),
    );
  }

  Widget _teacherCard(Map<String, String> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF00D83D)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAE8FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  data['inisial']!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6557D9),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['nama']!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF252525),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['keterangan']!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: Color(0xFF858585),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE0E3E7)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  'Hadir',
                  data['hadir']!,
                  const Color(0xFF16C784),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox('Izin', data['izin']!, const Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  'Sakit',
                  data['sakit']!,
                  const Color(0xFF858585),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        border: Border.all(color: const Color(0xFFE0E3E7)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 8,
              color: Color(0xFF858585),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── TOMBOL DOWNLOAD ──────────────────────────────────────────
  Widget _buildDownloadButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF43816B),
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Download Rekapan (Excel)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
