
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresensiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _bucketFoto = 'bukti-presensi';

  // Waktu Indonesia Barat (UTC+7)
  DateTime _waktuWib() {
    return DateTime.now().toUtc().add(
      const Duration(hours: 7),
    );
  }

  // Mengubah waktu dari database menjadi menit.
  int _waktuKeMenit(String waktu) {
    final bagian = waktu.split(':');

    final jam = int.parse(bagian[0]);
    final menit = int.parse(bagian[1]);

    return (jam * 60) + menit;
  }

  // Mengambil GPS terbaru.
  Future<Position> _ambilGPS() async {
    final aktif = await Geolocator.isLocationServiceEnabled();

    if (!aktif) {
      throw Exception('GPS HP belum diaktifkan.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi belum diberikan.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<Map<String, dynamic>> kirimPresensi({
    required File foto,
  }) async {
    String? pathFoto;

    try {
      // 1. Periksa sesi login.
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Silakan login kembali.');
      }

      // 2. Ambil data guru.
      final guru = await _supabase
          .from('guru')
          .select('guru_id, guru_jenis, status')
          .eq('user_id', user.id)
          .maybeSingle();

      if (guru == null) {
        throw Exception('Data guru tidak ditemukan.');
      }

      if (guru['status'] != 'Aktif') {
        throw Exception('Akun guru tidak aktif.');
      }

      final guruId = guru['guru_id'].toString();
      final guruJenis = guru['guru_jenis'].toString();

      // 3. Periksa perangkat yang terikat.
      final device = await _supabase
          .from('device')
          .select('status_binding')
          .eq('guru_id', guruId)
          .maybeSingle();

      if (device == null ||
          !['Aktif', 'Terikat'].contains(
            device['status_binding'],
          )) {
        throw Exception('Perangkat belum terverifikasi.');
      }

      // 4. Ambil jadwal berdasarkan jenis guru.
      final jadwal = await _supabase
          .from('jadwal')
          .select()
          .eq('jadwal_jenis', guruJenis)
          .maybeSingle();

      if (jadwal == null) {
        throw Exception('Jadwal guru belum tersedia.');
      }

      // 5. Periksa hari dan waktu WIB.
      final sekarang = _waktuWib();

      // Konvensi hari: Minggu = 0, Senin = 1, ... Sabtu = 6.
      final hariIni = sekarang.weekday % 7;

      final List<int> hariLibur =
          (jadwal['hari_libur'] as List? ?? [])
              .map((e) => (e as num).toInt())
              .toList();

      if (hariLibur.contains(hariIni)) {
        throw Exception('Hari ini tidak ada jadwal kelas.');
      }

      final menitSekarang =
          sekarang.hour * 60 + sekarang.minute;

      final menitMasuk = _waktuKeMenit(
        jadwal['jam_masuk'].toString(),
      );

      final menitBatas = _waktuKeMenit(
        jadwal['batas_presensi'].toString(),
      );

      if (menitSekarang < menitMasuk) {
        throw Exception(
          'Presensi belum dibuka. Presensi dimulai pukul 19.30.',
        );
      }

      if (menitSekarang > menitBatas) {
        throw Exception(
          'Batas waktu presensi telah berakhir.',
        );
      }

      // 6. Periksa presensi pada tanggal yang sama.
      final tanggal = [
        sekarang.year.toString().padLeft(4, '0'),
        sekarang.month.toString().padLeft(2, '0'),
        sekarang.day.toString().padLeft(2, '0'),
      ].join('-');

      final presensiSebelumnya = await _supabase
          .from('presensi')
          .select('presensi_id')
          .eq('guru_id', guruId)
          .eq('tanggal', tanggal)
          .limit(1);

      if ((presensiSebelumnya as List).isNotEmpty) {
        throw Exception(
          'Kamu sudah melakukan presensi hari ini.',
        );
      }

      // 7. Ambil lokasi sekolah aktif.
      final lokasi = await _supabase
          .from('lokasi_presensi')
          .select('lokasi_id, latitude, longitude, radius')
          .eq('status', true)
          .limit(1)
          .maybeSingle();

      if (lokasi == null) {
        throw Exception('Lokasi sekolah belum tersedia.');
      }

      // 8. Ambil GPS terbaru.
      final posisi = await _ambilGPS();

      final latitudeSekolah =
          (lokasi['latitude'] as num).toDouble();

      final longitudeSekolah =
          (lokasi['longitude'] as num).toDouble();

      final radius =
          (lokasi['radius'] as num).toDouble();

      final jarak = Geolocator.distanceBetween(
        posisi.latitude,
        posisi.longitude,
        latitudeSekolah,
        longitudeSekolah,
      );

      if (jarak > radius) {
        throw Exception(
          'Kamu berada di luar radius sekolah. '
          'Jarak: ${jarak.round()} meter.',
        );
      }

      // 9. Periksa file foto.
      if (!await foto.exists()) {
        throw Exception('Foto bukti presensi tidak ditemukan.');
      }

      // 10. Upload foto ke Supabase Storage.
      final namaFile =
          '${sekarang.year}'
          '${sekarang.month.toString().padLeft(2, '0')}'
          '${sekarang.day.toString().padLeft(2, '0')}_'
          '${sekarang.hour.toString().padLeft(2, '0')}'
          '${sekarang.minute.toString().padLeft(2, '0')}'
          '${sekarang.second.toString().padLeft(2, '0')}.jpg';

      pathFoto = '$guruId/$namaFile';

      await _supabase.storage
          .from(_bucketFoto)
          .upload(
            pathFoto,
            foto,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      // 11. Simpan data presensi.
      await _supabase.from('presensi').insert({
        'guru_id': guruId,
        'jadwal_id': jadwal['jadwal_id'],
        'lokasi_id': lokasi['lokasi_id'],
        'tanggal': tanggal,
        'jam':
            '${sekarang.hour.toString().padLeft(2, '0')}:'
            '${sekarang.minute.toString().padLeft(2, '0')}:'
            '${sekarang.second.toString().padLeft(2, '0')}',
        'status': 'Hadir',
        'latitude': posisi.latitude,
        'longitude': posisi.longitude,
        'validasi_gps': true,
        'waktu_presensi': DateTime.now().toUtc().toIso8601String(),
        'foto_bukti': pathFoto,
      });

      return {
        'success': true,
        'message': 'Presensi berhasil disimpan.',
        'foto_bukti': pathFoto,
        'jarak': jarak.round(),
      };
    } catch (e) {
      debugPrint('ERROR PRESENSI: $e');

      // Hapus foto jika upload berhasil tetapi insert gagal.
      if (pathFoto != null) {
        try {
          await _supabase.storage
              .from(_bucketFoto)
              .remove([pathFoto]);
        } catch (hapusError) {
          debugPrint('Gagal menghapus foto sementara: $hapusError');
        }
      }

      return {
        'success': false,
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }
}
