import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Layanan deep link untuk membuka detail notifikasi dari skema
/// `amikomstudent://notifikasi/<id>`.
class DeepLinkService {
  DeepLinkService._();

  static final instance = DeepLinkService._();

  static const _dedupeWindow = Duration(seconds: 2);

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  String? _pendingId;
  String? _lastHandledId;
  DateTime? _lastHandledAt;

  /// Mengekstrak ID notifikasi dari [uri].
  /// Mengembalikan `''` bila scheme != `amikomstudent`, host != `notifikasi`,
  /// atau path kosong.
  static String extractNotifId(Uri uri) {
    if (uri.scheme.toLowerCase() != 'amikomstudent') return '';
    if (uri.host.toLowerCase() != 'notifikasi') return '';
    for (final segment in uri.pathSegments) {
      final trimmed = segment.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  /// Menyimpan tautan awal (cold start) ke antrean pending. Dipisah dari
  /// pembacaan platform channel agar logika antrean bisa diuji.
  @visibleForTesting
  void seedPendingUri(Uri? uri) {
    if (uri == null) return;
    final id = extractNotifId(uri);
    if (id.isEmpty) return;
    _pendingId ??= id;
  }

  /// Mengambil tautan awal saat cold start dan menyimpannya ke antrean pending.
  Future<void> initFromInitialLink() async {
    try {
      seedPendingUri(await _appLinks.getInitialLink());
    } catch (_) {
      // Abaikan bila platform channel belum siap atau gagal membaca initial link.
    }
  }

  /// Inti logika penerimaan tautan: ekstrak ID, sinkronkan dengan pending (agar
  /// tautan awal tidak diproses dobel), buang duplikat dalam jendela dedupe, lalu
  /// kembalikan ID yang boleh dibuka. `null` = tidak ada yang perlu dibuka.
  String? handleUri(Uri uri) {
    final id = extractNotifId(uri);
    if (id.isEmpty) return null;
    if (_pendingId == id) {
      _pendingId = null;
    }
    if (_isDuplicate(id)) return null;
    _markHandled(id);
    return id;
  }

  /// Mendengarkan tautan masuk saat aplikasi berjalan (warm/background).
  void listen(void Function(String notifId) onNotifId) {
    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen((uri) {
      final id = handleUri(uri);
      if (id == null) return;
      onNotifId(id);
    }, onError: (_) {});
  }

  /// Mengambil dan mengosongkan ID notifikasi pending dari cold start.
  String? consumePendingId() {
    final id = _pendingId;
    _pendingId = null;
    if (id == null || id.isEmpty) return null;
    if (_isDuplicate(id)) return null;
    _markHandled(id);
    return id;
  }

  /// Menghentikan langganan stream deep link.
  void cancel() {
    _sub?.cancel();
    _sub = null;
  }

  bool _isDuplicate(String id) {
    final lastAt = _lastHandledAt;
    if (_lastHandledId == id &&
        lastAt != null &&
        DateTime.now().difference(lastAt) < _dedupeWindow) {
      return true;
    }
    return false;
  }

  void _markHandled(String id) {
    _lastHandledId = id;
    _lastHandledAt = DateTime.now();
  }
}
