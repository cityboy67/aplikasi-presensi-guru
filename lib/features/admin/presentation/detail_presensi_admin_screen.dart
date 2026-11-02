import 'package:flutter/material.dart';

/// Widget konten saja — tanpa Scaffold, AppBar, atau BottomNav.
/// Scaffold & navbar dihandle sepenuhnya oleh AdminDashboardScreen.
class DetailPresensiAdminScreen extends StatefulWidget {
  const DetailPresensiAdminScreen({super.key});

  @override
  State<DetailPresensiAdminScreen> createState() =>
      _DetailPresensiAdminScreenState();
}

class _DetailPresensiAdminScreenState extends State<DetailPresensiAdminScreen> {
  int _selectedCategoryIndex = 0;
  DateTime _selectedDate = DateTime(2026, 9, 1);

  String _formatMonthYear(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.year}';
  }

  final List<String> _categories = [
    'Semua (48)',
    'Izin Sakit',
    'Urusan Pribadi',
    'Izin lainnya',
  ];

  final List<Map<String, String>> _laporanList = List.generate(
    4,
    (index) => {
      'inisial': 'MB',
      'nama': 'Muhammad Budi, S.Pd., M.Kom.',
      'keterangan': 'Guru Matematika • NIP. 19840211',
      'jenis': 'Izin Sakit',
      'tanggal': '15 Sep 2026',
      'dokumen': 'Surat_Dokter.pdf',
      'ukuran': '(420 KB)',
      'waktu': '14 Sep, 19:20 WIB',
    },
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterPeriode(),
          const SizedBox(height: 12),
          _buildCategoryTabs(),
          const SizedBox(height: 16),
          _buildLaporanList(),
          const SizedBox(height: 24),
          _buildDownloadButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── FILTER PERIODE ───────────────────────────────────────────
  Widget _buildFilterPeriode() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filter Periode',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4A4A),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024, 1),
                lastDate: DateTime(2027, 12),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE0E3E7)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 14,
                    color: Color(0xFF6557D9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatMonthYear(_selectedDate),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF252525),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Color(0xFF858585),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTER KATEGORI ──────────────────────────────────────────
  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isActive = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF43816B) : Colors.white,
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF43816B)
                      : const Color(0xFFE0E3E7),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF858585),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── LIST LAPORAN ─────────────────────────────────────────────
  Widget _buildLaporanList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _laporanList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) => _buildReportCard(_laporanList[index]),
    );
  }

  Widget _buildReportCard(Map<String, String> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF00D83D)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9E7FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  data['inisial']!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF252525),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['keterangan']!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Color(0xFF858585),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Jenis Permohonan:',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Color(0xFF858585),
                      ),
                    ),
                    Text(
                      data['jenis']!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF252525),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tanggal Izin:',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Color(0xFF858585),
                      ),
                    ),
                    Text(
                      data['tanggal']!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6557D9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 14,
                    color: Color(0xFF6557D9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data['dokumen']!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00B0FF),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data['ukuran']!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Color(0xFF858585),
                    ),
                  ),
                ],
              ),
              Text(
                data['waktu']!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: Color(0xFF858585),
                ),
              ),
            ],
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
          minimumSize: const Size(double.infinity, 42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Download Laporan Resmi (Excel)',
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
