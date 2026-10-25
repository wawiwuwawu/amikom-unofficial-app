import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/agenda_terpadu.dart';
import '../utils/waktu.dart';

/// Helper gerbang tampil ujian — MURNI (tanpa state, tanpa fetch).
///
/// Sumber tanggal ujian adalah field `tanggal` (yyyy-MM-dd) pada baris ujian
/// agenda terpadu (perjanjian BE 2026-10-25). Karena agenda memang sudah
/// di-fetch JadwalPage/Dashboard/pengingat, tidak ada request tambahan dan
/// tidak ada memoize — hitungan lokal, murah, dan selalu sinkron dengan data
/// yang dirender.
///
/// Fail-open dua arah: baris tanpa `tanggal` (BE lama, atau BE gagal
/// mem-parse tanggal portal) dianggap lolos gerbang — ujian tampil seperti
/// sebelum fitur ini ada, tidak pernah hilang diam-diam.
class PeriodeUjianService {
  PeriodeUjianService._();

  /// Jumlah hari ke depan di mana baris ujian boleh tampil di agenda terpadu
  /// ("seminggu sebelumnya"). Dipakai bersama [JadwalPage] dan dashboard.
  @visibleForTesting
  static const ambangHariUjian = 7;

  /// Gerbang "dalam jendela tampil" untuk SATU baris ujian: `tanggalUjian`
  /// null → fail-open (tampil); ujian hari ini s.d. hari ini +
  /// [ambangHariUjian] - 1 → tampil; sisanya disembunyikan.
  static bool dalamJendela(DateTime? tanggalUjian, DateTime hariIni) {
    final tgl = tanggalUjian;
    if (tgl == null) return true;
    final tanggal = DateTime(tgl.year, tgl.month, tgl.day);
    final batas = hariIni.add(const Duration(days: ambangHariUjian - 1));
    return !tanggal.isBefore(hariIni) && !tanggal.isAfter(batas);
  }

  /// Periode ujian terdekat (tanggal ≥ [hariIni]) dari seluruh baris ujian
  /// agenda, sebagai `(tanggal, jenis)` — jenis 'UTS'/'UAS'. Dipakai teks
  /// banner JadwalPage. Null bila tidak ada baris ujian ber-tanggal yang
  /// belum lewat.
  static (DateTime, String)? periodeBerikutnya(
    AgendaTerpaduData data,
    DateTime hariIni,
  ) {
    (DateTime, String)? terdekat;
    for (final baris in data.agenda.values) {
      for (final item in baris) {
        final tipe = item.tipe.trim().toLowerCase();
        if (tipe != 'uts' && tipe != 'uas') continue;
        final tgl = tanggalDariPortal(item.tanggal ?? '');
        if (tgl == null || tgl.isBefore(hariIni)) continue;
        if (terdekat == null || tgl.isBefore(terdekat.$1)) {
          terdekat = (tgl, tipe.toUpperCase());
        }
      }
    }
    return terdekat;
  }
}
