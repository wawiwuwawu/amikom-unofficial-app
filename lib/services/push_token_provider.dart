import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/app_failure.dart';

/// Sumber token FCM (Firebase Cloud Messaging) untuk perangkat ini.
///
/// Seam (titik suntik) agar lapisan UI tidak bergantung langsung ke Firebase:
/// [NotifikasiListPage] menerima sebuah [PushTokenProvider], sementara
/// implementasi produksi dibuat terpisah di [FirebasePushTokenProvider].
abstract class PushTokenProvider {
  /// Mengambil token FCM perangkat ini, atau `null` bila belum tersedia.
  Future<String?> ambilToken();
}

/// Kontrak injeksi ke Firebase Cloud Messaging.
///
/// Dipisah dari [PushTokenProvider] agar properti internal
/// `FirebaseMessaging.instance` tidak pernah disentuh langsung oleh provider
/// maupun [PushService] — sehingga perilaku push bisa diuji tanpa Firebase.
abstract class MessagingGateway {
  Future<String?> getToken();

  /// Payload `{'token': '<token baru>'}`.
  Stream<Map<String, dynamic>> get tokenRefresh;

  /// Payload = map `data` pesan FCM yang diterima saat aplikasi di foreground.
  /// Judul/body dibaca dari `data['title']`/`data['body']` di lapisan service.
  Stream<Map<String, dynamic>> get onMessage;

  /// Payload = map `data` pesan FCM ketika pengguna menekan notifikasi yang
  /// ditampilkan FCM (aplikasi background/terminated).
  Stream<Map<String, dynamic>> get onMessageOpened;

  /// Map `data` pesan yang membuka aplikasi dari keadaan terminated, atau null.
  Future<Map<String, dynamic>?> getInitialMessage();

  /// Meminta izin notifikasi. Mengembalikan `true` bila diizinkan.
  Future<bool> mintaIzin();
}

/// Implementasi produksi [PushTokenProvider] yang meminta token FCM.
///
/// `const`-constructible tanpa argumen sehingga bisa dipakai sebagai nilai
/// default parameter UI. Firebase hanya tersentuh saat [ambilToken] dipanggil,
/// bukan saat konstruksi.
class FirebasePushTokenProvider implements PushTokenProvider {
  const FirebasePushTokenProvider({this.gateway = const FcmGatewayFirebase()});

  final MessagingGateway gateway;

  @override
  Future<String?> ambilToken() async {
    try {
      return await gateway.getToken();
    } catch (e) {
      // Log ringan TANPA nilai token; hanya tipe error yang aman dicatat.
      debugPrint('PushTokenProvider: gagal mengambil token (${e.runtimeType})');
      throw const AppFailure(
        'Gagal mengakses token FCM. Periksa koneksi lalu coba lagi.',
      );
    }
  }
}

/// Pembungkus [FirebaseMessaging] yang memenuhi kontrak [MessagingGateway].
class FcmGatewayFirebase implements MessagingGateway {
  const FcmGatewayFirebase();

  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  @override
  Stream<Map<String, dynamic>> get tokenRefresh => FirebaseMessaging
      .instance
      .onTokenRefresh
      .map((t) => <String, dynamic>{'token': t});

  @override
  Stream<Map<String, dynamic>> get onMessage =>
      FirebaseMessaging.onMessage.map((m) => m.data);

  @override
  Stream<Map<String, dynamic>> get onMessageOpened =>
      FirebaseMessaging.onMessageOpenedApp.map((m) => m.data);

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async =>
      (await FirebaseMessaging.instance.getInitialMessage())?.data;

  @override
  Future<bool> mintaIzin() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}
