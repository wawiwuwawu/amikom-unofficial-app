import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simpan pasangan ETag + body respons endpoint PUBLIK (data identik untuk
/// semua mahasiswa, tanpa PII — berita, pengumuman akademik, panduan, kalender
/// akademik; kontrak BE 2026-10-29, panduan-implement-fe §2.7) di
/// SharedPreferences.
///
/// Cara kerja bersama interceptor di [ApiClient]: request ulang menyertakan
/// `If-None-Match: <etag>`; bila BE menjawab `304 Not Modified` (tanpa body),
/// body terakhir yang tersimpan di sini dipakai kembali — bandwidth hemat,
/// tanpa mengubah kontrak service mana pun.
///
/// Fail-open KERAS: kegagalan baca/tulis pref hanya berarti tidak ada
/// penghematan — request tetap jalan normal, tidak pernah melempar ke pemanggil.
class EtagCacheService {
  EtagCacheService._();

  static final instance = EtagCacheService._();

  static const _prefKey = 'etag_cache_publik';

  /// Batas entri: endpoint publik yang di-cache sedikit (±6 bentuk request),
  /// jadi 40 sudah jauh melampaui kebutuhan; mencegah pref membengkak bila
  /// kombinasi query beragam.
  static const _maksEntri = 40;

  /// Cermin in-memory; pref hanya dimuat sekali per proses.
  final _entries = <String, Map<String, dynamic>>{};
  bool _dimuat = false;

  Future<void> _muatSekali() async {
    if (_dimuat) return;
    _dimuat = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((k, v) {
          if (v is Map && k is String) {
            _entries[k] = Map<String, dynamic>.from(v);
          }
        });
      }
    } catch (_) {
      // Pref rusak/tak terbaca → mulai kosong; request berikutnya menulis ulang.
      _entries.clear();
    }
  }

  Future<Map<String, dynamic>?> baca(String kunci) async {
    await _muatSekali();
    return _entries[kunci];
  }

  Future<void> simpan(String kunci, String etag, dynamic body) async {
    await _muatSekali();
    _entries[kunci] = {'etag': etag, 'body': body};
    // Eviksi FIFO sederhana bila melampaui batas.
    while (_entries.length > _maksEntri) {
      _entries.remove(_entries.keys.first);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(_entries));
    } catch (_) {
      // Gagal persist → cache hanya hidup di memori sesi ini.
    }
  }

  @visibleForTesting
  void resetForTest() {
    _entries.clear();
    _dimuat = false;
  }
}
