import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Status koneksi WiFi kampus yang ditampilkan indikator AppBar.
enum WifiKampusFase {
  /// Tidak berada di SSID `Hotspot@Amikom` (atau tak terbaca) — indikator
  /// disembunyikan.
  diLuar,

  /// Di WiFi kampus, portal belum terlewati (belum login / terputus / tanpa
  /// kredensial).
  terputus,

  /// Sedang mencoba login ke portal.
  mencoba,

  /// Login portal sukses + `generate_204` = 204 (internet nyata).
  terhubung,
}

/// Hasil satu attempt login portal (peta dari status native).
enum HasilPortal {
  berhasil,
  bukanWifiKampus,
  tanpaKredensial,
  kredensialSalah,
  loginDiterimaTanpaInternet,
  portalGagal,
  responsTakDikenal,
}

/// Seam platform-channel — supaya unit test tidak menyentuh MethodChannel /
/// native Android asli (pola sama dengan seam service lain).
abstract class WifiKampusGateway {
  /// Kirim kredensial ke memori native (dipakai attempt berikutnya).
  /// Username portal = NIM mahasiswa, password = tanggal lahir `yyyymmdd` —
  /// keduanya dari BE (kredensial siap pakai, FE tidak mende derive).
  Future<void> setCredentials(String username, String password);

  /// Hapus kredensial dari memori native.
  Future<void> clearCredentials();

  /// Coba login portal. Mengembalikan nama status dari native:
  /// berhasil / bukanWifiKampus / tanpaKredensial / kredensialSalah /
  /// loginDiterimaTanpaInternet / portalGagal / responsTakDikenal.
  Future<String> loginIfConnected();

  /// Status jaringan ringkas: {diWifiKampus, ssidTerbaca, portalTerjangkau,
  /// online}. `online` = generate_204 sukses (internet nyata di WiFi kampus).
  Future<Map<String, dynamic>> statusJaringan();

  /// Daftarkan callback yang dipanggil native saat WiFi kampus baru
  /// tersambung (NetworkCallback). Satu callback aktif (terakhir menang).
  void onWifiUp(VoidCallback callback);

  /// Daftarkan callback yang dipanggil setelah izin baca SSID baru saja
  /// diberikan (dialog ditutup granted) — pemanggil boleh trigger attempt.
  void mintaIzinSsidSetelahGranted(VoidCallback callback);

  /// Minta izin runtime baca SSID. true = dialog ditampilkan (atau sudah
  /// granted), false = tidak bisa meminta (bukan foreground / sudah granted).
  Future<bool> mintaIzinSsid() => Future.value(false);
}

class MethodChannelWifiKampusGateway implements WifiKampusGateway {
  static const _channel = MethodChannel('amikom/wifi_kampus');

  VoidCallback? _wifiUpCallback;
  VoidCallback? _izinGrantedCallback;

  MethodChannelWifiKampusGateway() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWifiUp') {
        _wifiUpCallback?.call();
      } else if (call.method == 'onIzinSsidGranted') {
        _izinGrantedCallback?.call();
      }
      return null;
    });
  }

  @override
  Future<void> setCredentials(String username, String password) => _channel
      .invokeMethod('setCredentials', {'username': username, 'password': password});

  @override
  Future<void> clearCredentials() => _channel.invokeMethod('clearCredentials');

  @override
  Future<String> loginIfConnected() async {
    final hasil = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('loginIfConnected')
        .then((m) => m?.cast<String, dynamic>());
    return hasil?['status'] as String? ?? 'portalGagal';
  }

  @override
  Future<Map<String, dynamic>> statusJaringan() async {
    final m = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('statusJaringan')
        .then((m) => m?.cast<String, dynamic>());
    return m ??
        const {
          'diWifiKampus': false,
          'ssidTerbaca': false,
          'portalTerjangkau': false,
          'online': false,
        };
  }

  @override
  void onWifiUp(VoidCallback callback) {
    _wifiUpCallback = callback;
  }

  @override
  void mintaIzinSsidSetelahGranted(VoidCallback callback) {
    _izinGrantedCallback = callback;
  }

  @override
  Future<bool> mintaIzinSsid() async {
    try {
      return await _channel.invokeMethod<bool>('mintaIzinSsid') ?? false;
    } on PlatformException {
      return false;
    }
  }
}

/// Auto-login WiFi kampus ("Hotspot@Amikom", portal MikroTik HTTP).
///
/// Mekanisme (acuan `auto-login-app/` + kontrak BE `GET /api/v1/wifi/kredensial`):
///  - Kredensial portal (username = NIM, password = tanggal lahir `yyyymmdd`)
///    diambil DARI BE saat internet JALAN normal (app open / resume) — saat
///    captive portal masih aktif, BE tidak terjangkau. Disimpan di
///    flutter_secure_storage (data sensitif — aturan §0.5) lalu dikirim ke
///    memori native per attempt.
///  - Attempt login HANYA saat di SSID kampus (dicek native, case-sensitive)
///    dan request dipaksa lewat antarmuka WiFi (bindProcessToNetwork native).
///  - BE menolak membentuk kredensial (502, `code` stabil) bila biodata
///    portal belum terisi — kondisi dicatat ([WifiKampusService.biodataKosong])
///    untuk penjelasan sheet/Profil; kredensial manual di Profil tetap bisa.
///  - Throttle 1 attempt / 5 menit; 3 kegagalan beruntun → backoff diam 24
///    jam (keputusan user: tanpa pesan, tanpa retry nagging — indikator ikon
///    cukup). Attempt manual dari UI tetap bisa menembus backoff.
///  - Seluruh jalur fail-open: galat apa pun tidak pernah mengganggu UI —
///    hanya mengubah fase indikator.
///
/// Pola mengikuti service lain: singleton + seam [WifiKampusGateway].
class WifiKampusService {
  WifiKampusService._({WifiKampusGateway? gatewayForTest})
      : _gateway = gatewayForTest ?? MethodChannelWifiKampusGateway() {
    _gateway.onWifiUp(() {
      // WiFi (apa pun) baru tersambung → sinkron fase + coba login (throttle
      // & backoff tetap berlaku). Native tidak bisa fetch BE di sini — portal
      // memblokir BE; cukup pakai kredensial cache.
      unawaited(attemptLogin(alasan: 'wifi-up'));
    });
    // Setelah dialog izin SSID diberikan → gerbang SSID native mulai bekerja;
    // coba attempt langsung tanpa menunggu event berikutnya.
    _gateway
        .mintaIzinSsidSetelahGranted(() => unawaited(attemptLogin(alasan: 'izin-granted')));
  }

  static final instance = WifiKampusService._();

  /// Factory khusus pengujian — menyuntikkan gateway palsu.
  @visibleForTesting
  static WifiKampusService untukTest(WifiKampusGateway gateway) =>
      WifiKampusService._(gatewayForTest: gateway);

  /// Kunci secure storage: username portal (= NIM, dari BE).
  static const _kUsername = 'wifi_kampus_username';

  /// Kunci secure storage: password portal (tanggal lahir `yyyymmdd`, BE).
  static const _kPassword = 'wifi_kampus_password';

  /// Kunci prefs: throttle attempt terakhir (epoch ms) — global per proses.
  static const _kAttemptTerakhir = 'wifi_kampus_attempt_at';

  /// Kunci prefs: hitungan kegagalan beruntun (untuk backoff).
  static const _kGagalBeruntun = 'wifi_kampus_gagal_beruntun';

  /// Kunci prefs: backoff aktif sampai epoch ms ini (3 gagal → 24 jam).
  static const _kBackoffUntil = 'wifi_kampus_backoff_until';

  /// Kunci prefs: toggle auto-login (default OFF — keputusan user 2026-11-12;
  /// bila belum pernah di-set, attempt otomatis hanya sinkron fase jaringan,
  /// tanpa kirim portal). Setting perangkat — dipertahankan saat logout.
  static const _kAutoLogin = 'wifi_kampus_auto_login';

  /// Kunci secure storage: override username manual dari halaman Profil.
  static const _kOverrideUsername = 'wifi_kampus_override_username';

  /// Kunci secure storage: override password manual dari halaman Profil.
  static const _kOverridePassword = 'wifi_kampus_override_password';

  /// Kunci prefs: flag override manual aktif.
  static const _kOverrideAktif = 'wifi_kampus_override_aktif';

  /// Jeda minimum antar attempt login portal.
  @visibleForTesting
  static const jedaThrottle = Duration(minutes: 5);

  /// Jumlah kegagalan beruntun sebelum backoff 24 jam aktif.
  @visibleForTesting
  static const ambangBackoff = 3;

  /// Durasi diam setelah [ambangBackoff] gagal beruntun.
  @visibleForTesting
  static const jedaBackoff = Duration(hours: 24);

  /// Endpoint BE kredensial WiFi (username + password siap pakai).
  static const endpointKredensial = '/api/v1/wifi/kredensial';

  /// Endpoint BE biodata (untuk pemulihan kredensial setelah override dihapus).
  static const endpointBiodata = '/api/v1/biodata';

  /// Kode error stabil dari BE (kontrak 2026-11-11): HTTP 502 — biodata
  /// portal belum terisi sehingga kredensial WiFi tidak dapat dibentuk.
  @visibleForTesting
  static const kodeBiodataKosong = 'biodata_tanggal_lahir_kosong';

  final WifiKampusGateway _gateway;
  final _secure = const FlutterSecureStorage();

  /// Fase yang dirender indikator AppBar.
  final ValueNotifier<WifiKampusFase> fase =
      ValueNotifier<WifiKampusFase>(WifiKampusFase.diLuar);

  /// Dipanggil saat fase BARU menjadi [WifiKampusFase.terhubung] (transisi,
  /// bukan pengulangan) — konsumen menampilkan snack halus sekali per
  /// transisi masuk jaringan.
  void Function()? onTerhubungPertama;

  bool _sedangBerjalan = false;
  bool _pernahTerhubungSesiIni = false;
  bool _izinSudahDiminta = false;
  Timer? _sinkronUlangTimer;

  /// Info terakhir dari BE: biodata portal belum terisi → kredensial WiFi
  /// tidak dapat dibentuk (502 + [kodeBiodataKosong], kontrak 2026-11-11).
  /// Kondisi PERMANEN sampai mahasiswa melengkapi biodata — berbeda dari
  /// galat sementara (offline/500). Direset saat kredensial berhasil
  /// didapat, override manual disimpan, atau logout.
  bool _biodataKosong = false;

  /// Sumber waktu untuk throttle & backoff — diganti di test agar tidak
  /// tidur nyata.
  @visibleForTesting
  DateTime Function() nowProvider = DateTime.now;

  /// Ambil kredensial WiFi dari BE + simpan cache secure storage + kirim ke
  /// memori native. Hanya bermakna saat internet jalan normal (app open /
  /// resume) — saat portal masih memblokir, request ini gagal dan diabaikan
  /// (fail-open).
  ///
  /// BE membentuk password dari biodata portal; bila mahasiswa belum mengisi
  /// biodata, BE menolak dengan 502 + `code: biodata_tanggal_lahir_kosong`
  /// (kontrak 2026-11-11) — kondisi permanen dicatat di [biodataKosong] untuk
  /// penjelasan UI; cache baik tetap tidak ditimpa. Galat lain (offline/500)
  /// dianggap sementara: status biodata tidak berubah.
  Future<void> segarkanKredensial() async {
    try {
      // Override manual aktif → kredensial BE tidak boleh menimpa pilihan
      // user (keputusan user: setting manual di Profil).
      if (await overrideAktif()) return;

      final response = await ApiClient.instance.dio.get(endpointKredensial);
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      final username = data['username']?.toString() ?? '';
      final password = data['password']?.toString() ?? '';
      if (username.isEmpty || password.isEmpty) {
        // Bentuk tak dikenal — jangan timpa cache baik.
        return;
      }
      _biodataKosong = false;
      await _secure.write(key: _kUsername, value: username);
      await _secure.write(key: _kPassword, value: password);
      await _gateway.setCredentials(username, password);
      // Kredensial segar → reset seluruh penghambat: kredensial lama mungkin
      // memang salah, sekarang data baru dari BE (alur pemulihan).
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kGagalBeruntun);
      await prefs.remove(_kBackoffUntil);
      await prefs.remove(_kAttemptTerakhir);
    } on DioException catch (e) {
      // Kontrak BE 2026-11-11: 502 + `code` stabil = biodata portal kosong
      // (bukan galat sementara) — catat agar UI bisa menjelaskan penyebab.
      if (_apakahBiodataKosong(e)) _biodataKosong = true;
      // Cache baik tidak ditimpa — pakai cache saja.
    } catch (_) {
      // BE gagal / offline / diblokir portal — pakai cache saja.
    }
  }

  /// Envelope 502 dari BE membawa `code` stabil (kontrak 2026-11-11)?
  /// Body bisa berupa Map (transformer produksi) atau String JSON (test) —
  /// [ApiClient.forceJsonMap] mengurusi keduanya.
  bool _apakahBiodataKosong(DioException e) {
    if (e.response?.statusCode != 502) return false;
    final body = ApiClient.forceJsonMap(e.response?.data);
    return body['code']?.toString() == kodeBiodataKosong;
  }

  /// Titik masuk utama — hook: splash (sebelum health check), app dibuka
  /// (MainPage post-frame), resume, dan WiFi kampus baru tersambung
  /// (callback native). Tidak pernah melempar.
  ///
  /// [bypassThrottle] true → jendela 5 menit diabaikan (dipakai splash:
  /// satu-satunya momen being-throttled = user stuck offline). Backoff 24
  /// jam & toggle auto-login TETAP dihormati.
  Future<void> attemptLogin({
    String alasan = 'app-open',
    bool bypassThrottle = false,
  }) async {
    if (_sedangBerjalan) return;
    _sedangBerjalan = true;
    try {
      final prefs = await SharedPreferences.getInstance();

      // 0. Toggle auto-login OFF → attempt otomatis TIDAK mengirim portal.
      //    Cukup sinkron fase jaringan (indikator tetap jujur); login hanya
      //    via tombol manual di Profil (cobaLoginManual tetap jalan).
      if (!await autoLoginAktif()) {
        await _setFaseDenganCekJaringan();
        return;
      }

      // 0.5 Izin baca SSID belum granted → minta sekali per sesi. Dialog
      //     tampil; attempt ini diteruskan (gerbang fail-open native tetap
      //     mencoba portal walau SSID belum terbaca).
      await pastikanIzinSsid();

      // 1. Backoff: 3 gagal beruntun → diam 24 jam (tanpa pesan, tanpa retry
      //    nagging — keputusan user). Attempt manual dari UI tetap bisa.
      final now = nowProvider().millisecondsSinceEpoch;
      final backoffUntil = prefs.getInt(_kBackoffUntil) ?? 0;
      if (backoffUntil > now) {
        await _setFaseDenganCekJaringan();
        return;
      }

      // 2. Throttle antar attempt. Cek SEBELUM fase `mencoba` — attempt yang
      //    di-skip tidak boleh meninggalkan spinner tersangkut (regresi
      //    tertangkap test). Splash boleh menembus jendela ini.
      final terakhir = prefs.getInt(_kAttemptTerakhir) ?? 0;
      if (!bypassThrottle &&
          terakhir != 0 &&
          now - terakhir < jedaThrottle.inMilliseconds) {
        return;
      }
      await prefs.setInt(_kAttemptTerakhir, now);

      _setFase(WifiKampusFase.mencoba);

      // 3. Sinkronkan kredensial dari cache secure storage ke memori native.
      await _sinkronKredensial();

      // 4. Attempt login lewat native (SSID gate + bind WiFi + POST portal).
      final hasil = _petakan(await _gateway.loginIfConnected());
      await _terapkanHasil(hasil);
    } catch (_) {
      // Fail-open: kegagalan tak terduga tidak pernah mengganggu UI.
      await _setFaseDenganCekJaringan();
    } finally {
      _sedangBerjalan = false;
    }

    // 5. Jaringan belum jelas (masih diLuar) → sinkron ulang SEKALI beberapa
    //    detik kemudian. Menutup race "app dibuka saat WiFi baru nyambung":
    //    pemeriksaan pertama jalan sebelum DHCP/portal settle dan menyimpulkan
    //    diLuar — tanpa pemeriksaan ulang, ikon tidak pernah muncul sampai
    //    user logout/login. Hanya sinkron FASE (bukan POST portal), jadi
    //    throttle/backoff tidak terpengaruh.
    if (fase.value == WifiKampusFase.diLuar) {
      _jadwalkanSinkronUlang();
    }
  }

  /// Attempt manual dari UI (sheet / nanti setting Profil) — melewati
  /// throttle & backoff (keputusan user: error sistem boleh di-trigger
  /// manual). Hasil tetap dicatat (gagal dihitung, sukses mereset).
  Future<HasilPortal> cobaLoginManual() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAttemptTerakhir, nowProvider().millisecondsSinceEpoch);
    _setFase(WifiKampusFase.mencoba);
    // Manual = user sedang melihat layar → dialog izin boleh muncul di sini.
    await pastikanIzinSsid();
    await _sinkronKredensial();
    try {
      final hasil = _petakan(await _gateway.loginIfConnected());
      await _terapkanHasil(hasil);
      return hasil;
    } catch (_) {
      await _setFaseDenganCekJaringan();
      return HasilPortal.portalGagal;
    }
  }

  /// Attempt untuk splash screen (dipanggil SEBELUM health check): satu
  /// percobaan login portal dengan batas waktu ketat — portal lambat tidak
  /// boleh menggantung startup. Menembus throttle 5 menit (splash =
  /// satu-satunya momen being-throttled = user stuck offline), tetap hormati
  /// toggle auto-login & backoff 24 jam. Tidak pernah melempar; hasil cukup
  /// lewat fase (indikator) — splash tidak menampilkan apa pun.
  Future<void> attemptLoginSplash() async {
    // Toggle OFF → pulang begitu saja: tanpa timer timeout, tanpa sentuh
    // gateway (cold-start test boot pun bersih — fase awal memang diLuar).
    if (!await autoLoginAktif()) return;
    try {
      await attemptLogin(alasan: 'splash', bypassThrottle: true).timeout(
        const Duration(seconds: 12),
      );
    } catch (_) {
      // Timeout / galat — splash langsung lanjut ke health check (fail-open).
      await _setFaseDenganCekJaringan();
    }
  }

  /// Minta izin runtime baca SSID (sekali per sesi, fail-open). Native
  /// menampilkan dialog; hasil granted memicu attempt lewat callback
  /// [mintaIzinSsidSetelahGranted] yang dipasang di constructor.
  @visibleForTesting
  Future<void> pastikanIzinSsid() async {
    if (_izinSudahDiminta) return;
    _izinSudahDiminta = true;
    try {
      await _gateway.mintaIzinSsid();
    } catch (_) {
      // Fail-open — tanpa izin pun gerbang fail-open native tetap mencoba.
    }
  }

  /// Status jaringan untuk sheet (di WiFi kampus? SSID terbaca?).
  Future<Map<String, dynamic>> statusJaringan() async {
    try {
      return await _gateway.statusJaringan();
    } catch (_) {
      return const {
        'diWifiKampus': false,
        'ssidTerbaca': false,
        'portalTerjangkau': false,
        'online': false,
      };
    }
  }

  /// Kredensial cache tersedia (username + password keduanya terisi)?
  Future<bool> punyaKredensial() async {
    try {
      final username = await _secure.read(key: _kUsername);
      final password = await _secure.read(key: _kPassword);
      return username != null &&
          username.isNotEmpty &&
          password != null &&
          password.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Backoff 24 jam sedang aktif? (untuk penjelasan sheet).
  Future<bool> sedangBackoff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final until = prefs.getInt(_kBackoffUntil) ?? 0;
      return until > nowProvider().millisecondsSinceEpoch;
    } catch (_) {
      return false;
    }
  }

  /// Biodata portal belum terisi (info terakhir dari BE)? Dipakai sheet WiFi
  /// & halaman Profil untuk menjelaskan MENGAPA kredensial server tidak
  /// tersedia — tanpa menampilkan detail teknis.
  bool get biodataKosong => _biodataKosong;

  @visibleForTesting
  set biodataKosong(bool nilai) => _biodataKosong = nilai;

  /// Toggle auto-login aktif? Default OFF (pref belum ada = OFF — keputusan
  /// user 2026-11-12: fitur opsional, user aktifkan sendiri di Profil).
  /// Dipertahankan saat logout (setting perangkat, bukan data sesi).
  Future<bool> autoLoginAktif() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kAutoLogin) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Set toggle auto-login (halaman Profil).
  Future<void> setAutoLogin(bool aktif) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAutoLogin, aktif);
    } catch (_) {
      // Fail-open: toggle gagal tersimpan — perilaku lama dipertahankan.
    }
    if (!aktif) await _setFaseDenganCekJaringan();
  }

  /// Override kredensial manual aktif? (ditandai flag prefs; kredensial
  /// override-nya di secure storage).
  Future<bool> overrideAktif() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kOverrideAktif) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Simpan override username/password manual (halaman Profil) — kredensial
  /// BE tidak akan menimpa sampai [hapusOverride] dipanggil. Langsung
  /// dipakai untuk attempt berikutnya.
  Future<void> simpanOverride(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await _secure.write(key: _kOverrideUsername, value: username);
    await _secure.write(key: _kOverridePassword, value: password);
    await prefs.setBool(_kOverrideAktif, true);
    // Override baru = kredensial berubah → penghambat lama tidak relevan.
    await prefs.remove(_kGagalBeruntun);
    await prefs.remove(_kBackoffUntil);
    // Kredensial manual membuat info "biodata kosong" tidak relevan lagi.
    _biodataKosong = false;
    await _gateway.setCredentials(username, password);
  }

  /// Hapus override → pulihkan kredensial dari BE (fetch ulang; bila BE
  /// gagal, cache kredensial utama tetap terpakai).
  Future<void> hapusOverride() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kOverrideAktif);
      await _secure.delete(key: _kOverrideUsername);
      await _secure.delete(key: _kOverridePassword);
    } catch (_) {}
    await segarkanKredensial();
  }

  /// Baca pasangan kredensial efektif (override bila aktif, selain itu cache
  /// utama) — untuk tampilan status di Profil. Tidak pernah melempar.
  Future<({String username, String password})?> kredensialEfektif() async {
    try {
      String? username;
      String? password;
      if (await overrideAktif()) {
        username = await _secure.read(key: _kOverrideUsername);
        password = await _secure.read(key: _kOverridePassword);
      }
      username ??= await _secure.read(key: _kUsername);
      password ??= await _secure.read(key: _kPassword);
      if (username == null ||
          username.isEmpty ||
          password == null ||
          password.isEmpty) {
        return null;
      }
      return (username: username, password: password);
    } catch (_) {
      return null;
    }
  }

  /// Hapus cache kredensial + state native + seluruh penghambat saat logout
  /// (pola sama dengan service lain — dipanggil SEBELUM `fullLogout`).
  /// Toggle auto-login DIPERTAHANKAN (setting perangkat, bukan data sesi).
  Future<void> bersihkanSaatLogout() async {
    try {
      await _secure.delete(key: _kUsername);
      await _secure.delete(key: _kPassword);
      await _secure.delete(key: _kOverrideUsername);
      await _secure.delete(key: _kOverridePassword);
    } catch (_) {}
    try {
      await _gateway.clearCredentials();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAttemptTerakhir);
    await prefs.remove(_kGagalBeruntun);
    await prefs.remove(_kBackoffUntil);
    await prefs.remove(_kOverrideAktif);
    _biodataKosong = false;
    _pernahTerhubungSesiIni = false;
    _sinkronUlangTimer?.cancel();
    _sinkronUlangTimer = null;
    fase.value = WifiKampusFase.diLuar;
  }

  // ── internal ──────────────────────────────────────────────────────────────

  /// Baca kredensial efektif → kirim ke memori native bila lengkap. Override
  /// manual (Profil) menang atas cache BE. Tidak bergantung NIM sesi —
  /// username sudah final dari BE.
  Future<void> _sinkronKredensial() async {
    try {
      String? username;
      String? password;
      if (await overrideAktif()) {
        username = await _secure.read(key: _kOverrideUsername);
        password = await _secure.read(key: _kOverridePassword);
      }
      username ??= await _secure.read(key: _kUsername);
      password ??= await _secure.read(key: _kPassword);
      if (username == null || username.isEmpty) return;
      if (password == null || password.isEmpty) return;
      await _gateway.setCredentials(username, password);
    } catch (_) {
      // Native belum siap (cold start awal) — attempt berikutnya menyinkron.
    }
  }

  Future<void> _terapkanHasil(HasilPortal hasil) async {
    switch (hasil) {
      case HasilPortal.berhasil:
        await _resetKegagalan();
        _setFase(WifiKampusFase.terhubung);
      case HasilPortal.bukanWifiKampus:
        // Bukan kegagalan kredensial/portal — tidak dihitung untuk backoff.
        _setFase(WifiKampusFase.diLuar);
      case HasilPortal.loginDiterimaTanpaInternet:
      case HasilPortal.portalGagal:
      case HasilPortal.responsTakDikenal:
        await _catatKegagalan();
        // Portal menerima tapi verifikasi 204 gagal / portal tak merespons —
        // tampilkan terputus; attempt berikutnya lewat throttle/backoff.
        _setFase(WifiKampusFase.terputus);
      case HasilPortal.tanpaKredensial:
      case HasilPortal.kredensialSalah:
        await _catatKegagalan();
        // Indikator tetap jujur: di kampus = terputus, di luar = sembunyi.
        await _setFaseDenganCekJaringan();
    }
  }

  /// Catat satu kegagalan attempt. Mencapai [ambangBackoff] → backoff 24 jam
  /// (counter di-reset — siklus berikutnya mendapat jatah 3 lagi).
  Future<void> _catatKegagalan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jumlah = (prefs.getInt(_kGagalBeruntun) ?? 0) + 1;
      if (jumlah >= ambangBackoff) {
        await prefs.setInt(
          _kBackoffUntil,
          nowProvider().add(jedaBackoff).millisecondsSinceEpoch,
        );
        await prefs.setInt(_kGagalBeruntun, 0);
      } else {
        await prefs.setInt(_kGagalBeruntun, jumlah);
      }
    } catch (_) {}
  }

  /// Reset hitungan kegagalan + backoff (dipanggil saat login berhasil).
  Future<void> _resetKegagalan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kGagalBeruntun);
      await prefs.remove(_kBackoffUntil);
    } catch (_) {}
  }

  /// Jeda sinkron ulang fase setelah app-open menyimpulkan diLuar (race WiFi
  /// baru nyambung — lihat langkah 5 di [attemptLogin]). Field (bukan const)
  /// supaya test bisa memperpendek — pola [nowProvider].
  @visibleForTesting
  Duration jedaSinkronUlang = const Duration(seconds: 8);

  /// Sinkron ulang fase SEKALI setelah [jedaSinkronUlang], hanya bila masih
  /// diLuar (network mungkin belum settle saat pemeriksaan pertama). Timer
  /// di-reset bila dipicu lagi; tidak pernah mengirim POST portal.
  void _jadwalkanSinkronUlang() {
    _sinkronUlangTimer?.cancel();
    _sinkronUlangTimer = Timer(jedaSinkronUlang, () async {
      _sinkronUlangTimer = null;
      if (fase.value != WifiKampusFase.diLuar) return;
      await _setFaseDenganCekJaringan();
    });
  }

  /// Set fase berdasar posisi jaringan nyata (dipakai saat keputusan bukan
  /// sekadar hasil login): kampus + online = terhubung (hijau — login bisa
  /// dari app ATAU browser, yang penting internet jalan), kampus belum
  /// online = terputus, di luar = sembunyi.
  Future<void> _setFaseDenganCekJaringan() async {
    try {
      final status = await _gateway.statusJaringan();
      if (status['diWifiKampus'] != true) {
        _setFase(WifiKampusFase.diLuar);
        return;
      }
      _setFase(
        status['online'] == true
            ? WifiKampusFase.terhubung
            : WifiKampusFase.terputus,
      );
    } catch (_) {
      _setFase(WifiKampusFase.diLuar);
    }
  }

  void _setFase(WifiKampusFase baru) {
    fase.value = baru;
    if (baru == WifiKampusFase.terhubung) {
      if (!_pernahTerhubungSesiIni) {
        _pernahTerhubungSesiIni = true;
        onTerhubungPertama?.call();
      }
    } else if (baru == WifiKampusFase.diLuar) {
      // Keluar dari WiFi kampus → transisi terhubung berikutnya boleh snack.
      _pernahTerhubungSesiIni = false;
    }
  }

  HasilPortal _petakan(String status) {
    switch (status) {
      case 'berhasil':
        return HasilPortal.berhasil;
      case 'bukanWifiKampus':
        return HasilPortal.bukanWifiKampus;
      case 'tanpaKredensial':
        return HasilPortal.tanpaKredensial;
      case 'kredensialSalah':
        return HasilPortal.kredensialSalah;
      case 'loginDiterimaTanpaInternet':
        return HasilPortal.loginDiterimaTanpaInternet;
      case 'responsTakDikenal':
        return HasilPortal.responsTakDikenal;
      default:
        return HasilPortal.portalGagal;
    }
  }
}
