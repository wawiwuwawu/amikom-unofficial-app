import 'package:flutter/foundation.dart'
    show debugPrint, visibleForTesting;

import '../models/jadwal_ujian.dart';
import '../utils/waktu.dart';
import 'akademik_service.dart';
import 'api_client.dart';

/// Info periode ujian terdekat yang belum lewat: tanggal mulai ujian +
/// label jenis ('UTS' / 'UAS').
@visibleForTesting
class PeriodeUjian {
  final DateTime tanggal;
  final String jenisLabel;

  const PeriodeUjian({required this.tanggal, required this.jenisLabel});
}

/// Layanan kecil pencari periode ujian terdekat dari jadwal-ujian (UTS + UAS).
///
/// Fail-open: fetch gagal, tidak ada baris ber-tanggal, atau semua ujian sudah
/// lewat → hasil `null` TANPA melempar ke UI — penelepon (gerbang tampil
/// ujian di jadwal/dashboard) lalu menampilkan ujian seperti semula.
///
/// Memoize per sesi di memori (tanpa SharedPreferences), ber-key NIM agar tak
/// bocor lintas akun saat logout→login: hasil sukses bertahan 10 menit,
/// hasil gagal/kosong 5 menit — supaya pindah tab tidak meng-hammer endpoint.
/// Fetch yang sedang berjalan dibagi (in-flight dedupe) sehingga JadwalPage
/// dan Dashboard yang memuat bersamaan hanya memicu satu pasang request.
class PeriodeUjianService {
  PeriodeUjianService._();

  static final instance = PeriodeUjianService._();

  final _akademik = AkademikService();

  /// Jumlah hari ke depan di mana baris ujian boleh tampil di agenda terpadu
  /// ("seminggu sebelumnya"). Dipakai bersama [JadwalPage] dan dashboard.
  @visibleForTesting
  static const ambangHariUjian = 7;

  static const _ttlSukses = Duration(minutes: 10);
  static const _ttlGagal = Duration(minutes: 5);

  (DateTime, String)? _cacheNilai;
  bool _cacheTerisi = false;
  DateTime _cacheWaktu = DateTime.fromMillisecondsSinceEpoch(0);
  String _cacheNim = '';
  Future<(DateTime, String)?>? _muatBerjalan;

  String get _nim {
    final nim = ApiClient.instance.nim;
    return (nim != null && nim.isNotEmpty) ? nim : '';
  }

  /// Mereset memoize. Hanya untuk pengujian.
  @visibleForTesting
  void resetUntukTest() {
    _cacheNilai = null;
    _cacheTerisi = false;
    _cacheWaktu = DateTime.fromMillisecondsSinceEpoch(0);
    _cacheNim = '';
    _muatBerjalan = null;
  }

  /// Hapus memoize saat logout — periode ujian milik mahasiswa lama tidak
  /// boleh menggerbangi agenda mahasiswa baru. Dipanggil dari titik logout.
  void bersihkanSaatLogout() {
    _cacheNilai = null;
    _cacheTerisi = false;
    _cacheNim = '';
    _muatBerjalan = null;
  }

  /// Tanggal ujian terdekat yang belum lewat, atau `null` bila tidak ada
  /// ujian mendatang / tanggal tak terbaca / fetch gagal (fail-open).
  Future<(DateTime, String)?> tanggalUjianTerdekat() {
    final nim = _nim;
    if (_cacheTerisi && _cacheNim == nim) {
      final ttl = _cacheNilai != null ? _ttlSukses : _ttlGagal;
      if (DateTime.now().difference(_cacheWaktu) < ttl) {
        return Future.value(_cacheNilai);
      }
    }
    // In-flight dedupe: pemanggil bersamaan menunggu fetch yang sama.
    final berjalan = _muatBerjalan;
    if (berjalan != null) return berjalan;
    final muat = _muat(nim);
    _muatBerjalan = muat;
    return muat;
  }

  Future<(DateTime, String)?> _muat(String nim) async {
    (DateTime, String)? hasil;
    try {
      final hasilLists = await Future.wait([
        _akademik.getJadwalUjian('uts'),
        _akademik.getJadwalUjian('uas'),
      ]);
      final hariIni = _hariIni();
      hasil = pilihTerdekat(hasilLists[0], hasilLists[1], hariIni);
    } catch (e) {
      // Fail-open: kegagalan fetch diperlakukan "tidak ada info periode",
      // bukan galat — jangan sampai gerbang membuat halaman error.
      debugPrint('PeriodeUjianService: fetch gagal (${e.runtimeType})');
      hasil = null;
    }
    _cacheNilai = hasil;
    _cacheTerisi = true;
    _cacheWaktu = DateTime.now();
    _cacheNim = nim;
    _muatBerjalan = null;
    return hasil;
  }

  /// Pilih baris ujian dengan tanggal minimum yang ≥ [hariIni]. Tanggal tak
  /// terbaca (`tanggalDariDdMmYyyy` null) dilewati. Hanya untuk pengujian.
  @visibleForTesting
  static (DateTime, String)? pilihTerdekat(
    List<JadwalUjian> uts,
    List<JadwalUjian> uas,
    DateTime hariIni,
  ) {
    (DateTime, String)? terdekat;
    void pertimbangkan(List<JadwalUjian> daftar, String jenis) {
      for (final baris in daftar) {
        final tgl = tanggalDariDdMmYyyy(baris.tanggal);
        if (tgl == null || tgl.isBefore(hariIni)) continue;
        if (terdekat == null || tgl.isBefore(terdekat!.$1)) {
          terdekat = (tgl, jenis);
        }
      }
    }

    pertimbangkan(uts, 'UTS');
    pertimbangkan(uas, 'UAS');
    return terdekat;
  }

  /// Gerbang "dalam jendela tampil": `periode` null → fail-open (tampil);
  /// ujian hari ini s.d. hari ini + [ambangHariUjian] - 1 → tampil.
  /// Sumber tunggal untuk JadwalPage dan dashboard supaya tidak divergen.
  static bool dalamJendela((DateTime, String)? periode, DateTime hariIni) {
    final p = periode;
    if (p == null) return true;
    final tgl = p.$1;
    final tanggal = DateTime(tgl.year, tgl.month, tgl.day);
    final batas = hariIni.add(const Duration(days: ambangHariUjian - 1));
    return !tanggal.isBefore(hariIni) && !tanggal.isAfter(batas);
  }

  DateTime _hariIni() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
