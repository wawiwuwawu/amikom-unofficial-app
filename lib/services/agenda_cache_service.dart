import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/agenda_terpadu.dart';
import 'api_client.dart';

/// Cache agenda terpadu (stale-while-revalidate) milik NIM aktif.
///
/// Kontrak SWR (kesepakatan Fase 1c):
///  * Cache HANYA dipakai untuk render instan — setiap muat dengan koneksi
///    TETAP fetch ulang dan hasilnya menimpa cache via [simpan].
///  * Label "data terakhir" (lihat [terakhirDisimpan]) hanya muncul saat
///    fetch gagal tetapi cache masih ada.
///
/// Pola mengikuti [PengingatJadwalService]: kunci ber-suffix NIM, serializer
/// JSON bentuk sama dengan `AgendaTerpaduData.fromJson`, dan seluruh method
/// tidak pernah melempar (fail-open: gagal baca/simpan hanya dilog).
/// CATATAN serializer: salinan kecil dari
/// `PengingatJadwalService._agendaKeJson` (tidak diekstrak bersama agar test
/// `test/pengingat_jadwal_service_test.dart` tidak tersentuh). Satu bedanya
/// sengaja: salinan ini MENYERTAKAN field `tanggal` baris ujian — gerbang
/// tampil ujian di Dashboard membaca field itu dari data cache.
class AgendaCacheService {
  AgendaCacheService._();

  static final instance = AgendaCacheService._();

  /// Kunci SharedPreferences (ber-suffix NIM bila tersedia): payload agenda.
  static const _kCacheAgenda = 'agenda_terpadu_cache';

  /// Kunci timestamp pembaruan (epoch ms) untuk label "data terakhir".
  static const _kCacheAgendaAt = 'agenda_terpadu_cache_at';

  /// Suffix NIM aktif, pola sama dengan [PengingatJadwalService]: `_<nim>`
  /// bila tersedia, string kosong bila tidak.
  String _suffixNim() {
    final nim = ApiClient.instance.nim;
    return (nim != null && nim.isNotEmpty) ? '_$nim' : '';
  }

  /// Baca cache agenda milik NIM aktif. Null bila kosong/korup — tidak pernah
  /// melempar.
  Future<AgendaTerpaduData?> baca() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_kCacheAgenda${_suffixNim()}');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AgendaTerpaduData.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('AgendaCache: gagal membaca cache (${e.runtimeType})');
    }
    return null;
  }

  /// Simpan [data] + timestamp pembaruan. Tidak pernah melempar.
  Future<void> simpan(AgendaTerpaduData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final suffix = _suffixNim();
      await prefs.setString('$_kCacheAgenda$suffix', _agendaKeJson(data));
      await prefs.setInt(
        '$_kCacheAgendaAt$suffix',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('AgendaCache: gagal menyimpan cache (${e.runtimeType})');
    }
  }

  /// Waktu cache terakhir diperbarui (untuk label "data terakhir"), atau
  /// null bila belum pernah tersimpan. Tidak pernah melempar.
  Future<DateTime?> terakhirDisimpan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final at = prefs.getInt('$_kCacheAgendaAt${_suffixNim()}');
      if (at != null && at > 0) {
        return DateTime.fromMillisecondsSinceEpoch(at);
      }
    } catch (e) {
      debugPrint('AgendaCache: gagal membaca timestamp (${e.runtimeType})');
    }
    return null;
  }

  /// Hapus cache milik NIM aktif (dan kunci tanpa suffix) saat logout.
  /// Pola loop sama dengan [PengingatJadwalService.bersihkanSaatLogout] dan
  /// wajib dipanggil SEBELUM `ApiClient.instance.fullLogout`.
  Future<void> bersihkanSaatLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final suffix = _suffixNim();
      for (final s in [suffix, '']) {
        await prefs.remove('$_kCacheAgenda$s');
        await prefs.remove('$_kCacheAgendaAt$s');
      }
    } catch (e) {
      debugPrint('AgendaCache: pembersihan logout gagal (${e.runtimeType})');
    }
  }

  /// Serialisasi agenda minimal (map bucket → list item) — bentuk sama dengan
  /// `AgendaTerpaduData.fromJson` sehingga cache bisa dinyah-serialisasi ulang.
  /// Salinan `PengingatJadwalService._agendaKeJson` + field `tanggal` (lihat
  /// catatan kelas).
  String _agendaKeJson(AgendaTerpaduData agenda) => jsonEncode({
    'total_agenda': agenda.totalAgenda,
    'agenda': {
      for (final entry in agenda.agenda.entries)
        entry.key: [
          for (final item in entry.value)
            {
              'tipe': item.tipe,
              'hari': item.hari,
              'jam': item.jam,
              'jam_mulai': item.jamMulai,
              'jam_selesai': item.jamSelesai,
              'ruang': item.ruang,
              'matakuliah': item.matakuliah,
              'detail': item.detail,
              if (item.komponen != null) 'komponen': item.komponen,
              if (item.tanggal != null) 'tanggal': item.tanggal,
            },
        ],
    },
  });
}
