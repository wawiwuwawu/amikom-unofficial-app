import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notifikasi.dart' show NotifikasiRateLimited;
import '../pages/notifikasi_detail_page.dart';
import 'deep_link_service.dart';
import 'navigation_service.dart';
import 'notifikasi_service.dart';
import 'push_token_provider.dart';

/// Lapisan push FCM: membuat channel Android, menampilkan notifikasi lokal
/// untuk pesan foreground, dan mengarahkan ketukan notifikasi ke detail notif
/// lewat skema deep link yang SUDAH ada. Tidak menciptakan routing baru; akses
/// Firebase terpusat pada [MessagingGateway]/[FcmGatewayFirebase].
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  static const _channelId = 'notifikasi_kampus';
  static const _channelName = 'Notifikasi Kampus';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  MessagingGateway? _gateway;

  /// Token terakhir yang kita daftarkan ke server. Disimpan di MEMORI saja
  /// (static field, TANPA SharedPreferences) — cukup untuk dibersihkan saat
  /// logout dalam satu sesi.
  static String? _lastToken;

  /// Ketukan notifikasi yang datang sebelum UI siap (cold start).
  static String? _pendingOpenId;

  /// Menyiapkan channel Android, plugin notifikasi lokal, dan subscription FCM.
  Future<void> init({MessagingGateway? gateway}) async {
    final activeGateway = gateway ?? const FcmGatewayFirebase();
    _gateway = activeGateway;

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi akademik dan pengumuman kampus',
      importance: Importance.high,
      playSound: true,
    );
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(channel);

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _handleTap(response.payload),
    );

    activeGateway.tokenRefresh.listen(_onTokenRefresh, onError: (_) {});
    activeGateway.onMessage.listen(
      (data) {
        unawaited(_tampilkanNotifikasi(data));
      },
      onError: (_) {},
    );
    activeGateway.onMessageOpened.listen(_handleOpened, onError: (_) {});
    unawaited(_bukaDariInitial(activeGateway));
  }

  /// Meminta izin notifikasi. `true` bila diizinkan. Tidak melempar ke UI.
  Future<bool> mintaIzin() async {
    try {
      final gateway = _gateway ?? const FcmGatewayFirebase();
      return await gateway.mintaIzin();
    } catch (e) {
      debugPrint('PushService: permintaan izin gagal (${e.runtimeType})');
      return false;
    }
  }

  /// Mengekstrak ID notifikasi dari [data]: coba `data['url']` lewat parser
  /// deep link yang SUDAH ada, lalu fallback `data['notif_id']`. Null bila tak
  /// ada.
  static String? idDariData(Map<String, dynamic> data) {
    final rawUrl = data['url'];
    if (rawUrl is String && rawUrl.trim().isNotEmpty) {
      final uri = Uri.tryParse(rawUrl);
      if (uri != null) {
        final fromUrl = DeepLinkService.extractNotifId(uri);
        if (fromUrl.isNotEmpty) return fromUrl;
      }
    }
    final rawId = data['notif_id'];
    if (rawId != null) {
      final id = rawId.toString().trim();
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  /// Menyelesaikan id notifikasi lalu menerapkan dedupe jendela ±2 detik lewat
  /// [DeepLinkService.instance]. Mengembalikan id yang boleh dibuka, atau null
  /// bila tak valid / duplikat. Tidak melakukan navigasi — bisa diuji langsung.
  @visibleForTesting
  String? resolveOpenedId(Map<String, dynamic> data) {
    final id = idDariData(data);
    if (id == null) return null;
    final uri = Uri.tryParse('amikomstudent://notifikasi/$id');
    if (uri == null) return null;
    return DeepLinkService.instance.handleUri(uri);
  }

  /// Mendaftarkan [token] ke server dan menyimpannya sebagai `_lastToken`.
  /// TIDAK melempar ke pemanggil UI: 429 didiamkan (sudah dicoba), error lain
  /// hanya dilog. Nilai token tidak pernah dicatat.
  Future<void> daftarkanToken(String token) async {
    _lastToken = token;
    try {
      await NotifikasiService().daftarkanToken(token);
    } on NotifikasiRateLimited {
      // Sudah dicoba server baru-baru ini — diamkan agar tidak membanjiri.
    } catch (e) {
      debugPrint('PushService: gagal mendaftarkan token (${e.runtimeType})');
    }
  }

  /// Best-effort hapus token saat logout (token kosong = hapus semua untuk NIM
  /// ini). Tidak melempar.
  Future<void> bersihkanSaatLogout() async {
    final token = _lastToken;
    try {
      await NotifikasiService().hapusToken(token ?? '');
    } catch (e) {
      debugPrint('PushService: gagal menghapus token saat logout (${e.runtimeType})');
    } finally {
      _lastToken = null;
    }
  }

  /// Bila NIM ini sudah opt-in (punya minimal satu token), ambil token FCM lalu
  /// daftarkan. Dipanggil saat startup untuk memulihkan setelah reinstall.
  /// Tidak melempar.
  Future<void> daftarkanUlangJikaAktif() async {
    try {
      final status = await NotifikasiService().getOptinStatus();
      if (!status.enabled) return;
      // Push sudah aktif sebelumnya (mis. setelah reinstall): pastikan izin
      // notifikasi Android 13+ tetap ada agar pesan tak hilang diam-diam.
      await mintaIzin();
      final gateway = _gateway ?? const FcmGatewayFirebase();
      final token = await gateway.getToken();
      if (token != null && token.isNotEmpty) {
        await daftarkanToken(token);
      }
    } catch (e) {
      debugPrint('PushService: daftar-ulang token dilewati (${e.runtimeType})');
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _onTokenRefresh(Map<String, dynamic> payload) {
    final token = payload['token'];
    if (token is String && token.isNotEmpty) {
      unawaited(daftarkanToken(token));
    }
  }

  void _handleOpened(Map<String, dynamic> data) {
    final id = resolveOpenedId(data);
    if (id != null) _openNotifikasi(id);
  }

  void _handleTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final uri = Uri.tryParse(payload);
    if (uri == null) return;
    final id = DeepLinkService.instance.handleUri(uri);
    if (id != null) _openNotifikasi(id);
  }

  Future<void> _bukaDariInitial(MessagingGateway gateway) async {
    final data = await gateway.getInitialMessage();
    if (data != null) _handleOpened(data);
  }

  void _openNotifikasi(String id) {
    final navigator = NavigationService.instance.navigatorKey.currentState;
    if (navigator == null) {
      // Cold start: FCM bisa mengirim tapped message sebelum UI siap. Antre;
      // dijalankan oleh MainPage lewat [terapkanPendingTerbuka].
      _pendingOpenId = id;
      debugPrint('PushService: ketukan notifikasi ditunda sampai UI siap');
      return;
    }
    unawaited(
      navigator.push(
        MaterialPageRoute(builder: (_) => NotifikasiDetailPage(id: id)),
      ),
    );
  }

  /// Menjalankan ketukan notifikasi yang ditunda saat cold start (dipanggil
  /// MainPage setelah frame pertama, saat navigator sudah tersedia).
  Future<void> terapkanPendingTerbuka() async {
    final id = _pendingOpenId;
    if (id == null) return;
    _pendingOpenId = null;
    _openNotifikasi(id);
  }

  /// Id tampil notifikasi yang stabil: `notif_id` bila ada (numerik apa adanya,
  /// selain itu hash), jika tidak hash dari url/judul. Dimasker ke 32-bit
  /// tak-negatif agar aman untuk id notifikasi Android.
  int _displayId(Map<String, dynamic> data) {
    const mask = 0x7fffffff;
    final rawId = data['notif_id'];
    if (rawId != null) {
      final asInt = int.tryParse(rawId.toString().trim());
      return (asInt ?? rawId.toString().hashCode) & mask;
    }
    final url = data['url'];
    final key = (url is String && url.isNotEmpty)
        ? url
        : (data['title']?.toString() ?? '');
    return key.hashCode & mask;
  }

  Future<void> _tampilkanNotifikasi(Map<String, dynamic> data) async {
    final rawTitle = data['title'];
    final title = (rawTitle is String && rawTitle.trim().isNotEmpty)
        ? rawTitle
        : _channelName;
    final body = data['body']?.toString() ?? '';
    final rawUrl = data['url'];
    final payload = rawUrl is String ? rawUrl : null;
    try {
      await _plugin.show(
        id: _displayId(data),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Notifikasi akademik dan pengumuman kampus',
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('PushService: gagal menampilkan notifikasi lokal (${e.runtimeType})');
    }
  }
}
