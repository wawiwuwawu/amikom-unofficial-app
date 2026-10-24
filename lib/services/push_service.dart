import 'dart:async' show unawaited;

import 'package:dio/dio.dart' show DioException;
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_failure.dart' show AppFailure;
import '../models/notifikasi.dart' show NotifikasiRateLimited;
import '../pages/notifikasi_list_page.dart';
import 'deep_link_service.dart';
import 'navigation_service.dart';
import 'notifikasi_service.dart';
import 'push_token_provider.dart';

/// Aksi ketukan push yang bisa dijalankan setelah UI siap.
///
/// Keputusan user: SEMUA ketukan (push pribadi, siaran http/https, foreground,
/// background, maupun cold start) membuka halaman DAFTAR notifikasi sebagai
/// pintasan — perilaku "buka detail spesifik" dan "buka browser eksternal"
/// dihapus. Detail tetap bisa diakses user dari halaman daftar.
sealed class AksiTerbuka {
  const AksiTerbuka();
}

/// Buka halaman daftar notifikasi (pintasan — perilaku ketukan saat ini).
class AksiBukaList extends AksiTerbuka {
  const AksiBukaList();

  @override
  bool operator ==(Object other) => other is AksiBukaList;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Lapisan push FCM: membuat channel Android, menampilkan notifikasi lokal
/// untuk pesan foreground, dan mengarahkan SEMUA ketukan notifikasi ke halaman
/// daftar notifikasi sebagai pintasan. Ekstraksi id + dedupe 2 detik tetap
/// berjalan ([DeepLinkService] untuk jalur privat, dedupe lokal untuk siaran)
/// supaya ketukan ganda — termasuk kedatangan ganda deep link + pesan FCM —
/// tidak mendorong dua halaman ke navigator. Akses Firebase terpusat pada
/// [MessagingGateway]/[FcmGatewayFirebase].
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  static const _channelId = 'notifikasi_kampus';
  static const _channelName = 'Notifikasi Kampus';

  /// Jendela dedupe ketukan siaran: url sama di dalam jendela ini dianggap
  /// ketukan ganda (selaras dengan jendela dedupe milik [DeepLinkService]).
  static const _dedupeSiaranWindow = Duration(seconds: 2);

  /// Kunci SharedPreferences: izin notifikasi pernah DITOLAK oleh user. Ditulis
  /// sekali oleh [aktifkanJikaBelumPernah] supaya dialog izin tidak muncul di
  /// setiap aplikasi dibuka; dihapus begitu token berhasil didaftarkan (user
  /// boleh berubah pikiran, mis. mengizinkan dari Pengaturan sistem).
  static const _kIzinDitolak = 'push_izin_pernah_ditolak';

  /// Kunci SharedPreferences: sheet panduan sistem ([showNotifikasiPushSheet])
  /// sudah pernah ditampilkan kepada user — cukup sekali, dipakai halaman
  /// notifikasi saat status push sudah Aktif.
  static const _kSheetDitampilkan = 'push_sheet_ditampilkan';

  /// Guard sesi: aktivasi otomatis hanya dicoba SEKALI per launch aplikasi,
  /// supaya pemanggil dari login + halaman utama tak meminta izin dua kali
  /// maupun mendaftarkan token ganda di launch yang sama.
  static bool _aktivasiSudahDicoba = false;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  MessagingGateway? _gateway;

  /// Token terakhir yang kita daftarkan ke server. Disimpan di MEMORI saja
  /// (static field, TANPA SharedPreferences) — cukup untuk dibersihkan saat
  /// logout dalam satu sesi.
  static String? _lastToken;

  /// Aksi ketukan yang datang sebelum UI siap (cold start) — pertama menang.
  static AksiTerbuka? _pendingTerbuka;

  /// Jendela dedupe PUSHER halaman list: push daftar kedua dalam jendela ini
  /// dibatalkan. Melindungi navigator dari kedatangan ganda satu ketukan lewat
  /// dua mekanisme (deep link app_links + pesan FCM) yang kunci dedupe-nya
  /// berbeda (id vs url).
  static const _dedupeListWindow = Duration(seconds: 2);
  DateTime? _listTerakhirAt;

  /// `true` bila aktivasi terakhir gagal karena PERANGKAT/build (gateway FCM
  /// tak siap — mis. `google-services.json` hilang / Play Services mati),
  /// bukan karena server atau izin. Dipakai kartu push supaya tidak memandu
  /// user ke Pengaturan sistem ketika tak ada setelan yang bisa menolong.
  static bool _tokenGagalDiPerangkat = false;

  /// Percobaan registrasi token terakhir GAGAL karena SERVER (mis. adapter
  /// push 503 — FCM belum dikonfigurasi). Beda dari [_tokenGagalDiPerangkat]:
  /// pengguna tak bisa berbuat apa-apa di perangkat; kartu status memakai pesan
  /// server, bukan panduan Pengaturan. Dibersihkan saat registrasi sukses dan
  /// saat sesi login baru ([mulaiSesiBaru]).
  static bool _serverGagalTerakhir = false;

  /// Lihat [_tokenGagalDiPerangkat] — hanya untuk dibaca lapisan UI.
  static bool get tokenGagalDiPerangkat => _tokenGagalDiPerangkat;

  /// Lihat [_serverGagalTerakhir] — hanya untuk dibaca lapisan UI.
  static bool get serverGagalTerakhir => _serverGagalTerakhir;

  /// Dedupe LOKAL ketukan siaran (browser): url + waktu terakhir dibuka.
  /// Jaringan ini terpisah dari dedupe privat milik [DeepLinkService] supaya
  /// siaran dan notifikasi privat tak saling menelan.
  String? _siaranTerakhir;
  DateTime? _siaranTerakhirAt;

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

  /// Meminta izin notifikasi lewat [gateway]. `true` bila diizinkan. Tidak
  /// melempar ke UI: error gateway dilog dan diperlakukan sebagai penolakan.
  Future<bool> _mintaIzin(MessagingGateway gateway) async {
    try {
      return await gateway.mintaIzin();
    } catch (e) {
      debugPrint('PushService: permintaan izin gagal (${e.runtimeType})');
      return false;
    }
  }

  /// Memetakan [data] ketukan menjadi [AksiTerbuka]: `url` amikomstudent →
  /// buka list (id diekstrak [resolveTujuan] untuk dedupe), `url` http/https →
  /// buka list (KEPUTUSAN USER: tidak lagi dibuka di browser), tanpa url →
  /// fallback `notif_id` (string/angka, di-trim) → buka list. Null bila
  /// ketukan tidak dikenal — pemanggil membiarkannya (no-op aman).
  static AksiTerbuka? tujuanDariData(Map<String, dynamic> data) {
    final rawUrl = data['url'];
    if (rawUrl is String && rawUrl.trim().isNotEmpty) {
      final uri = Uri.tryParse(rawUrl);
      if (uri != null) {
        if (uri.scheme == 'amikomstudent') {
          final fromUrl = DeepLinkService.extractNotifId(uri);
          if (fromUrl.isNotEmpty) return const AksiBukaList();
        } else if (uri.scheme == 'http' || uri.scheme == 'https') {
          return const AksiBukaList();
        }
      }
    }
    final rawId = data['notif_id'];
    if (rawId != null) {
      final id = rawId.toString().trim();
      if (id.isNotEmpty) return const AksiBukaList();
    }
    return null;
  }

  /// Menyelesaikan [tujuanDariData] lalu menerapkan dedupe: privat (url
  /// amikomstudent maupun fallback `notif_id`) lewat [DeepLinkService.instance]
  /// (jendela ±2 detik, jaringan yang SUDAH ada), siaran lewat dedupe LOKAL
  /// berjendela [_dedupeSiaranWindow]. Mengembalikan aksi yang boleh dijalankan
  /// (selalu [AksiBukaList] saat ini), atau null bila tak valid / duplikat.
  /// Tidak membuka apa pun — bisa diuji langsung.
  @visibleForTesting
  AksiTerbuka? resolveTujuan(Map<String, dynamic> data) {
    if (tujuanDariData(data) == null) return null;

    final rawUrl = data['url'];
    final uri = rawUrl is String && rawUrl.trim().isNotEmpty
        ? Uri.tryParse(rawUrl.trim())
        : null;
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return _bukanDuplikatSiaran(uri) ? const AksiBukaList() : null;
    }

    // Jalur privat: ekstrak id (url dulu, fallback notif_id) lalu dedupe lewat
    // DeepLinkService — meski tujuannya list, dedupe tetap berjalan agar
    // ketukan ganda dalam 2 detik tidak mendorong halaman kedua.
    var id = '';
    if (uri != null && uri.scheme == 'amikomstudent') {
      id = DeepLinkService.extractNotifId(uri);
    }
    if (id.isEmpty) {
      final rawId = data['notif_id'];
      if (rawId != null) id = rawId.toString().trim();
    }
    if (id.isEmpty) return null;
    final dedupeUri = Uri.tryParse('amikomstudent://notifikasi/$id');
    if (dedupeUri == null) return null;
    final accepted = DeepLinkService.instance.handleUri(dedupeUri);
    if (accepted == null) return null;
    return const AksiBukaList();
  }

  /// Dedupe LOKAL ketukan siaran: url sama dalam [_dedupeSiaranWindow] dianggap
  /// ketukan ganda (dua siaran berbeda beruntun tetap lolos). Dipisah dari
  /// dedupe privat [DeepLinkService] agar dua jalur tak saling menelan.
  bool _bukanDuplikatSiaran(Uri url) {
    final kunci = url.toString();
    final terakhirAt = _siaranTerakhirAt;
    final sekarang = DateTime.now();
    if (terakhirAt != null &&
        _siaranTerakhir == kunci &&
        sekarang.difference(terakhirAt) < _dedupeSiaranWindow) {
      return false;
    }
    _siaranTerakhir = kunci;
    _siaranTerakhirAt = sekarang;
    return true;
  }

  /// Mendaftarkan [token] ke server dan menyimpannya sebagai `_lastToken`.
  /// TIDAK melempar ke pemanggil UI: 429 didiamkan (sudah dicoba), error lain
  /// hanya dilog. Nilai token tidak pernah dicatat.
  Future<void> daftarkanToken(String token) async {
    _lastToken = token;
    try {
      await NotifikasiService().daftarkanToken(token);
      // Pendaftaran berhasil: jangan kunci flag penolakan izin yang ditulis
      // [aktifkanJikaBelumPernah] — izin bisa sudah diberikan ulang di sistem.
      _tokenGagalDiPerangkat = false;
      _serverGagalTerakhir = false;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kIzinDitolak) ?? false) {
        await prefs.setBool(_kIzinDitolak, false);
      }
    } on NotifikasiRateLimited {
      // Sudah dicoba server baru-baru ini — diamkan agar tidak membanjiri.
      _serverGagalTerakhir = false;
    } catch (e) {
      // Kegagalan SERVER (mis. 503 adapter FCM belum siap) ditandai agar kartu
      // status tak salah memandu ke Pengaturan perangkat. Kegagalan perangkat
      // sudah ditandai terpisah oleh [_tokenGagalDiPerangkat].
      if (e is AppFailure || e is DioException) _serverGagalTerakhir = true;
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

  /// Default-on untuk user BARU: dipanggil sekali tepat setelah login sukses.
  /// Izin notifikasi diminta sekali; bila diterima token langsung didaftarkan
  /// tanpa perlu user menekan tombol. Tidak melempar — kegagalan izin atau FCM
  /// tidak boleh mengganggu alur login.
  ///
  /// Guard sesi [_aktivasiSudahDicoba] membuat pemanggilan kedua di launch yang
  /// sama (mis. dari halaman utama) langsung dilewati.
  ///
  /// [gateway] hanya untuk pengujian; produksi memakai gateway dari [init].
  Future<void> aktifkanSetelahLogin({MessagingGateway? gateway}) async {
    if (_aktivasiSudahDicoba) return;
    _aktivasiSudahDicoba = true;
    final aktif = gateway ?? _gateway ?? const FcmGatewayFirebase();
    try {
      final diizinkan = await _mintaIzin(aktif);
      if (!diizinkan) return; // panduan ke Pengaturan sistem ada di kartu
      final token = await aktif.getToken();
      if (token == null || token.isEmpty) {
        _tokenGagalDiPerangkat = true;
        return;
      }
      await daftarkanToken(token);
    } catch (e) {
      // DioException = kegagalan SERVER (bukan perangkat); sisanya
      // (gateway/Firebase) dicatat agar kartu tak memandu ke setelan sistem.
      if (e is! DioException) _tokenGagalDiPerangkat = true;
      debugPrint('Push: aktivasi setelah login dilewati (${e.runtimeType})');
    }
  }

  /// Default-on untuk user LAMA yang sudah pernah login tapi belum punya token
  /// (mis. masuk sebelum fitur push ada). Dipanggil SETELAH frame pertama dari
  /// [MainPage], supaya dialog izin tidak muncul di atas splash saat cold start.
  ///
  /// Bila NIM sudah aktif (reinstall/ganti perangkat), cukup daftar ulang token
  /// terbaru. Bila belum, izin diminta SEKALI — penolakan dicatat di
  /// SharedPreferences agar dialog tidak muncul tiap aplikasi dibuka; bila izin
  /// ditolak permanen, kartu di halaman notifikasi memandu user ke Pengaturan
  /// sistem (tak ada tombol Aktifkan di aplikasi).
  ///
  /// Guard sesi [_aktivasiSudahDicoba] membuat pemanggilan kedua di launch yang
  /// sama (mis. setelah login) langsung dilewati.
  ///
  /// [gateway] hanya untuk pengujian; produksi memakai gateway dari [init].
  ///
  /// [paksa] mengabaikan guard sesi — dipakai halaman notifikasi saat app
  /// dilanjutkan (resume) dan status masih Nonaktif (mis. server baru saja
  /// diperbaiki). Tanpa ini, guard sekali-per-proses membuat recovery tidak
  /// pernah berjalan pada launch yang sama: kartu bisa tetap "Nonaktif"
  /// seumur hidup app meski user sudah mengizinkan notifikasi.
  Future<void> aktifkanJikaBelumPernah({
    MessagingGateway? gateway,
    bool paksa = false,
  }) async {
    if (_aktivasiSudahDicoba && !paksa) return;
    _aktivasiSudahDicoba = true;
    final aktif = gateway ?? _gateway ?? const FcmGatewayFirebase();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kIzinDitolak) ?? false) {
      // Flag penolakan TIDAK boleh jadi jalan buntu: bila user sudah
      // mengizinkan notifikasi lewat Pengaturan sistem (kartu memandu ke
      // sana), probe izin menemukannya — lanjutkan agar token terdaftar dan
      // flag dibersihkan oleh [daftarkanToken].
      if (!await _probeIzin(aktif)) return;
      await prefs.setBool(_kIzinDitolak, false);
    }
    try {
      final status = await NotifikasiService().getOptinStatus();
      if (status.enabled) {
        // Push sudah aktif: pastikan izin Android 13+ masih ada (probe tanpa
        // dialog; kalau ternyata hilang, minta sekali), lalu segarkan token
        // (FCM bisa merotasi token).
        if (!await _probeIzin(aktif)) await _mintaIzin(aktif);
        final token = await aktif.getToken();
        if (token != null && token.isNotEmpty) await daftarkanToken(token);
        return;
      }
      final diizinkan = await _probeIzin(aktif) || await _mintaIzin(aktif);
      if (!diizinkan) {
        await prefs.setBool(_kIzinDitolak, true);
        return;
      }
      final token = await aktif.getToken();
      if (token == null || token.isEmpty) {
        _tokenGagalDiPerangkat = true;
        return;
      }
      await daftarkanToken(token);
    } catch (e) {
      // 401 (sesi belum pulih) maupun gateway belum siap: coba lagi di launch
      // berikutnya — tidak pernah mengganggu alur masuk aplikasi.
      if (e is! DioException) _tokenGagalDiPerangkat = true;
      debugPrint('Push: aktivasi default dilewati (${e.runtimeType})');
    }
  }

  /// Probe izin TANPA dialog. Kegagalan probe (mis. gateway belum siap)
  /// dianggap "belum diizinkan" supaya alur tak melempar.
  Future<bool> _probeIzin(MessagingGateway gateway) async {
    try {
      return await gateway.izinSudahDiberikan();
    } catch (e) {
      debugPrint('PushService: probe izin gagal (${e.runtimeType})');
      return false;
    }
  }

  /// Menandai percobaan aktivasi untuk sesi login BARU (logout → login dalam
  /// proses yang sama). Tanpa ini, guard sekali-per-proses akan memblokir
  /// pendaftaran token setelah user login ulang, dan push mati diam-diam
  /// sampai aplikasi di-restart.
  void mulaiSesiBaru() {
    _aktivasiSudahDicoba = false;
    _serverGagalTerakhir = false;
  }

  // ── Panduan sistem (sheet) ───────────────────────────────────────────────

  /// Sheet panduan sistem (izin notifikasi + pengecualian optimasi baterai)
  /// sudah pernah ditampilkan? Dipakai halaman notifikasi supaya panduan
  /// muncul sekali saja, tepat setelah push otomatis terdaftar aktif.
  static Future<bool> sheetSudahDitampilkan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSheetDitampilkan) ?? false;
  }

  /// Menandai sheet panduan sudah ditampilkan. Kegagalan prefs didiamkan —
  /// panduan akan muncul lagi di lain waktu, bukan alasan untuk melempar.
  static Future<void> tandaiSheetDitampilkan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSheetDitampilkan, true);
    } catch (e) {
      debugPrint('Push: gagal menyimpan status sheet (${e.runtimeType})');
    }
  }

  /// Mereset guard sesi [_aktivasiSudahDicoba]. Hanya untuk pengujian: setiap
  /// test butuh percobaan aktivasi baru karena guard-nya statis per proses.
  @visibleForTesting
  static void resetAktivasiUntukTest() {
    _aktivasiSudahDicoba = false;
  }

  /// Mereset antrean pending ketukan dan guard dedupe list. Hanya untuk
  /// pengujian — keduanya state singleton per proses.
  @visibleForTesting
  static void resetPendingUntukTest() {
    _pendingTerbuka = null;
    instance._listTerakhirAt = null;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _onTokenRefresh(Map<String, dynamic> payload) {
    final token = payload['token'];
    if (token is String && token.isNotEmpty) {
      unawaited(daftarkanToken(token));
    }
  }

  void _handleOpened(Map<String, dynamic> data) {
    final aksi = resolveTujuan(data);
    if (aksi == null) return;
    _jalankanAksi(aksi);
  }

  /// Ketukan notifikasi lokal (foreground). Payload adalah `data['url']` asli;
  /// dibungkus jadi map lalu diperlakukan persis seperti ketukan push lain.
  /// Payload kosong/tak dikenal = no-op aman (resolveTujuan mengembalikan null).
  void _handleTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    _handleOpened({'url': payload});
  }

  /// Menjalankan [aksi]: membuka halaman daftar notifikasi. Gagal apapun tidak
  /// melempar — ketukan bisa datang dari background tanpa konteks UI yang aman.
  void _jalankanAksi(AksiTerbuka aksi) {
    switch (aksi) {
      case AksiBukaList():
        _bukaList();
    }
  }

  /// Membuka [NotifikasiListPage] sebagai pintasan ketukan notifikasi.
  /// Bila navigator belum tersedia (cold start), aksi diantrekan dan dijalankan
  /// [MainPage] lewat [terapkanPendingTerbuka] sehingga list tidak pernah
  /// ditumpuk di atas Splash/Login. Push kedua dalam jendela
  /// [_dedupeListWindow] dibatalkan supaya satu ketukan yang datang lewat dua
  /// mekanisme (deep link + FCM) tidak membuka dua halaman.
  void _bukaList() {
    final navigator = NavigationService.instance.navigatorKey.currentState;
    if (navigator == null) {
      _pendingTerbuka ??= const AksiBukaList();
      debugPrint('PushService: ketukan notifikasi ditunda sampai UI siap');
      return;
    }
    final terakhirAt = _listTerakhirAt;
    final sekarang = DateTime.now();
    if (terakhirAt != null &&
        sekarang.difference(terakhirAt) < _dedupeListWindow) {
      return;
    }
    _listTerakhirAt = sekarang;
    unawaited(
      navigator.push(
        MaterialPageRoute(builder: (_) => const NotifikasiListPage()),
      ),
    );
  }

  Future<void> _bukaDariInitial(MessagingGateway gateway) async {
    final data = await gateway.getInitialMessage();
    if (data != null) _handleOpened(data);
  }

  /// Menjalankan aksi ketukan yang ditunda saat cold start (dipanggil MainPage
  /// setelah frame pertama, saat navigator sudah tersedia). Bila pending sudah
  /// ada, ketukan berikutnya tak menimpanya (pertama menang).
  Future<void> terapkanPendingTerbuka() async {
    final aksi = _pendingTerbuka;
    if (aksi == null) return;
    _pendingTerbuka = null;
    _jalankanAksi(aksi);
  }

  /// Dipakai [MainPage]: ketukan deep link `amikomstudent` yang sudah lewat
  /// dedupe [DeepLinkService] tetap harus melewati guard list terpusat
  /// ([_bukaList]) supaya kedatangan ganda satu ketukan lewat dua mekanisme
  /// (deep link + pesan FCM) tidak membuka dua halaman daftar.
  void bukaListDariKetukan() => _bukaList();

  /// Id tampil notifikasi yang stabil. **Siaran (url http/https) selalu memakai
  /// hash url** — walaupun BE juga mengirim `notif_id` untuk siaran, id mentah
  /// itu berbagi namespace dengan notifikasi privat dan bisa saling replace di
  /// tray Android. Privat tetap `notif_id` (numerik apa adanya, selain itu
  /// hash). Dimasker ke 32-bit tak-negatif agar aman untuk id notifikasi
  /// Android.
  @visibleForTesting
  static int displayIdDari(Map<String, dynamic> data) {
    const mask = 0x7fffffff;
    final url = data['url'];
    if (url is String && url.isNotEmpty) {
      final scheme = Uri.tryParse(url)?.scheme ?? '';
      if (scheme == 'http' || scheme == 'https') {
        return url.hashCode & mask;
      }
    }
    final rawId = data['notif_id'];
    if (rawId != null) {
      final asInt = int.tryParse(rawId.toString().trim());
      return (asInt ?? rawId.toString().hashCode) & mask;
    }
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
        id: displayIdDari(data),
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
