import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/notifikasi.dart';
import '../models/app_failure.dart';

class NotifikasiService {
  final _dio = ApiClient.instance.dio;
  static const _storageKey = 'read_notification_ids';

  /// Batas penyimpanan id yang sudah dibaca. Dulu 200, tapi itu BUG: bila
  /// daftar notifikasi > 200 item, pemangkasan membuang mark item terbaru
  /// sehingga item bolak-balik tampil "Baru" setelah "Tandai Dibaca"
  /// (terverifikasi lewat repro: daftar 325 id → hanya 200 tersimpan).
  /// 2000 masih murah untuk SharedPreferences (puluhan KB) dan di atas
  /// volume daftar yang realistis.
  static const _maxReadIds = 2000;
  static const _optinEndpoint = '/api/v1/notifikasi/optin';
  static const _deviceTokenEndpoint = '/api/v1/notifikasi/device-token';
  Future<List<NotifikasiItem>> getNotifikasi() =>
      ApiClient.guard<List<NotifikasiItem>>(() async {
        final response = await _dio.get('/api/v1/notifikasi');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return ApiClient.unwrapList<NotifikasiItem>(
          data,
          NotifikasiItem.fromJson,
        );
      }, 'Gagal memuat notifikasi');

  Future<NotifikasiDetail> getNotifikasiDetail(
    String id,
  ) => ApiClient.guard<NotifikasiDetail>(() async {
    final endpoint = '/api/v1/notifikasi/$id';
    late Response<dynamic> response;
    try {
      response = await _dio.get(endpoint);
    } on DioException catch (e) {
      // 404 diterjemahkan di sini — bukan di `ApiClient.handleError` global —
      // supaya endpoint lain (mis. unduhan PDF) tidak ikut memakai redaksi ini.
      if (e.response?.statusCode == 404) {
        final data = e.response?.data;
        final pesan = data is Map ? (data['message'] ?? data['error']) : data;
        throw AppFailure.fromServer(
          pesan,
          fallback: 'Notifikasi tidak ditemukan atau sudah dihapus',
        );
      }
      rethrow;
    }
    final raw = ApiClient.unwrapData<dynamic>(response.data);

    Map<String, dynamic> jsonMap = ApiClient.forceJsonMap(raw);

    if (jsonMap.isEmpty) {
      throw const AppFailure('Format data detail notifikasi tidak valid');
    }

    final detail = NotifikasiDetail.fromJson(jsonMap);

    if (detail.judul.isEmpty && detail.konten.isEmpty) {
      final msg = jsonMap['message']?.toString();
      if (msg != null && msg.isNotEmpty) {
        throw AppFailure.fromServer(
          msg,
          fallback: 'Data notifikasi tidak tersedia',
        );
      }
      throw const AppFailure('Data notifikasi tidak tersedia');
    }

    return detail;
  }, 'Gagal memuat detail notifikasi');

  Never _rethrowPushDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    // Diagnostik aman: method + path + status (TANPA token/header/body).
    debugPrint(
      'NotifikasiService: ${e.requestOptions.method} '
      '${e.requestOptions.path} -> $statusCode',
    );
    if (statusCode == 503) {
      throw const AppFailure(
        'Layanan notifikasi push sedang dinonaktifkan oleh server.',
      );
    }
    if (statusCode == 429) {
      final rawRetry = e.response?.headers.value('retry-after')?.trim();
      final parsed = rawRetry != null ? int.tryParse(rawRetry) : null;
      final seconds = (parsed != null && parsed > 0) ? parsed : 60;
      throw NotifikasiRateLimited(seconds);
    }
    throw e;
  }

  /// `GET /api/v1/notifikasi/optin` → `{enabled, token_count}`.
  /// `enabled` = NIM pemanggil punya minimal satu token FCM terdaftar.
  Future<NotifikasiOptinStatus> getOptinStatus() =>
      ApiClient.guard<NotifikasiOptinStatus>(() async {
        try {
          final response = await _dio.get(_optinEndpoint);
          final raw = ApiClient.unwrapData<dynamic>(response.data);
          return NotifikasiOptinStatus.fromJson(ApiClient.forceJsonMap(raw));
        } on DioException catch (e) {
          _rethrowPushDioError(e);
        }
      }, 'Gagal memuat status notifikasi push');

  /// `POST /api/v1/notifikasi/device-token` body `{token, platform}` —
  /// mendaftarkan token FCM perangkat ini milik NIM pemanggil.
  Future<NotifikasiOptinStatus> daftarkanToken(String token) =>
      ApiClient.guard<NotifikasiOptinStatus>(() async {
        try {
          final response = await _dio.post(
            _deviceTokenEndpoint,
            data: {'token': token, 'platform': 'android'},
          );
          ApiClient.unwrapMutation(response.data).ensureSuccess();
          final raw = ApiClient.unwrapData<dynamic>(response.data);
          return NotifikasiOptinStatus.fromJson(
            ApiClient.forceJsonMap(raw),
          );
        } on DioException catch (e) {
          _rethrowPushDioError(e);
        }
      }, 'Gagal mengaktifkan notifikasi push');

  /// `DELETE /api/v1/notifikasi/device-token` — dengan [token] menghapus satu
  /// token, dengan token kosong menghapus SEMUA token milik NIM ini.
  /// Idempoten: sukses walau tokennya sudah tidak ada.
  Future<void> hapusToken(String token) => ApiClient.guard<void>(() async {
    try {
      final response = await _dio.delete(
        _deviceTokenEndpoint,
        data: token.isEmpty ? null : {'token': token},
      );
      ApiClient.unwrapMutation(response.data).ensureSuccess();
    } on DioException catch (e) {
      _rethrowPushDioError(e);
    }
  }, 'Gagal menonaktifkan notifikasi push');

  List<String> _pruneIds(Iterable<String> ids) {
    final list = ids.toList();
    if (list.length <= _maxReadIds) return list;
    return list.sublist(list.length - _maxReadIds);
  }

  /// Kunci penyimpanan status baca: `read_notification_ids_<nim>` bila NIM sudah
  /// diketahui; bila belum (mis. hasil upgrade yang belum menyimpan `nim`), pakai
  /// kunci lama supaya status baca tetap terbaca. Migrasi ke kunci per-NIM
  /// dilakukan sekali begitu NIM tersedia.
  Future<String> _prepareScopedKey(SharedPreferences prefs) async {
    final nim = ApiClient.instance.nim?.trim();
    if (nim == null || nim.isEmpty) return _storageKey;
    final key = '${_storageKey}_$nim';
    if (prefs.containsKey(_storageKey) && !prefs.containsKey(key)) {
      final legacy = prefs.getStringList(_storageKey) ?? const <String>[];
      await prefs.setStringList(key, _pruneIds(legacy));
      await prefs.remove(_storageKey);
    }
    return key;
  }

  Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _prepareScopedKey(prefs);
    final list = prefs.getStringList(key) ?? const <String>[];
    return list.toSet();
  }

  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _prepareScopedKey(prefs);
    final readSet = (prefs.getStringList(key) ?? const <String>[]).toSet();
    readSet.remove(id);
    readSet.add(id);
    await prefs.setStringList(key, _pruneIds(readSet));
  }

  Future<void> markAllAsRead(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _prepareScopedKey(prefs);
    final readSet = (prefs.getStringList(key) ?? const <String>[]).toSet();
    for (final id in ids) {
      readSet.remove(id);
      readSet.add(id);
    }
    await prefs.setStringList(key, _pruneIds(readSet));
  }

  Future<int> getUnreadCount() async {
    try {
      final items = await getNotifikasi();
      final readIds = await getReadIds();
      return items.where((item) => !readIds.contains(item.id)).length;
    } catch (_) {
      return 0;
    }
  }
}
