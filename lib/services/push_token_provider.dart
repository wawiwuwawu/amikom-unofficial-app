import 'package:firebase_messaging/firebase_messaging.dart';

/// Kontrak injeksi ke Firebase Cloud Messaging (FCM).
///
/// Dipisahkan agar properti internal `FirebaseMessaging.instance` tidak pernah
/// disentuh langsung oleh [PushService] maupun lapisan UI — sehingga perilaku
/// push (izin, token, pesan masuk) bisa diuji tanpa Firebase. File ini kini
/// hanya berisi gateway FCM; registrasi token ke server dikerjakan
/// [PushService] lewat gateway ini.
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

  /// Memeriksa izin notifikasi TANPA memunculkan dialog. `true` bila izin
  /// sudah diberikan (termasuk yang diaktifkan user lewat Pengaturan sistem).
  Future<bool> izinSudahDiberikan();
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

  @override
  Future<bool> izinSudahDiberikan() async {
    final settings = await FirebaseMessaging.instance
        .getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}
