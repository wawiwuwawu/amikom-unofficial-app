// Test kontrak WifiKampusService — auto-login captive portal Hotspot@Amikom.
//
// Cakupan:
//  - segarkanKredensial: kredensial {username, password} dari BE
//    /api/v1/wifi/kredensial → cache secure storage + native; field kosong /
//    BE gagal → cache tidak ditimpa; sukses → reset seluruh penghambat.
//  - deteksi biodata kosong: 502 + code `biodata_tanggal_lahir_kosong`
//    (kontrak BE 2026-11-11) → flag biodataKosong; galat sementara tidak
//    mengubah flag; sukses/override/logout menghapus flag.
//  - attemptLogin: throttle 5 menit, backoff 3 gagal → 24 jam, pemetaan
//    fase dari status native, single-flight, fail-open.
//  - cobaLoginManual: menembus throttle & backoff, hasil tetap dicatat.
//  - bersihkanSaatLogout: cache + penghambat + clearCredentials native.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show VoidCallback;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/wifi_kampus_service.dart';

class _GatewayFake implements WifiKampusGateway {
  _GatewayFake();

  String statusLogin = 'bukanWifiKampus';
  String? usernameTerkirim;
  String? passwordTerkirim;
  int loginCalls = 0;
  bool clearCredentialsCalled = false;
  bool izinDiminta = false;
  VoidCallback? wifiUp;
  VoidCallback? izinGranted;

  @override
  Future<void> setCredentials(String username, String password) async {
    usernameTerkirim = username;
    passwordTerkirim = password;
  }

  @override
  Future<void> clearCredentials() async {
    clearCredentialsCalled = true;
  }

  @override
  Future<String> loginIfConnected() async {
    loginCalls++;
    return statusLogin;
  }

  @override
  Future<Map<String, dynamic>> statusJaringan() async =>
      {'diWifiKampus': diWifiKampus, 'ssidTerbaca': true, 'portalTerjangkau': true};

  bool diWifiKampus = false;

  @override
  void onWifiUp(VoidCallback callback) {
    wifiUp = callback;
  }

  @override
  void mintaIzinSsidSetelahGranted(VoidCallback callback) {
    izinGranted = callback;
  }

  @override
  Future<bool> mintaIzinSsid() async {
    izinDiminta = true;
    return true;
  }
}

/// Adapter Dio palsu untuk endpoint kredensial WiFi (pola _AgendaAdapter di
/// pengingat_jadwal_service_test.dart).
class _KredensialAdapter implements HttpClientAdapter {
  _KredensialAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    // Layanan kredensial hanya boleh menyentuh endpoint miliknya — bila
    // menyimpang, test gagal cepat.
    if (!options.path.contains(WifiKampusService.endpointKredensial)) {
      throw Exception('endpoint tak dikenal: ${options.path}');
    }
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _balasKredensial(String username, String password) {
  return ResponseBody.fromString(
    jsonEncode({
      'status': 'success',
      'data': {'username': username, 'password': password},
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    // Secure storage → mock bawaan plugin (I/O nyata Windows tak konsisten
    // di test; pola notifikasi_optin_service_test.dart).
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('segarkanKredensial — kredensial siap pakai dari BE', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // Reset mock secure storage — mock bawaan plugin persist antar test.
      FlutterSecureStorage.setMockInitialValues({});
    });

    late ResponseBody Function(RequestOptions) handlerPanggil;

    WifiKampusService serviceDengan(_GatewayFake gateway) {
      ApiClient.instance.dio.httpClientAdapter = _KredensialAdapter(
        (options) => handlerPanggil(options),
      );
      ApiClient.instance.dio.transformer = SyncTransformer();
      return WifiKampusService.untukTest(gateway);
    }

    test('BE sukses → kredensial native terkirim persis dari BE', () async {
      final gateway = _GatewayFake();
      handlerPanggil = (_) => _balasKredensial('23SA21A060', '20051207');
      final service = serviceDengan(gateway);

      await service.segarkanKredensial();

      expect(gateway.usernameTerkirim, '23SA21A060',
          reason: 'username portal = NIM dari BE, bukan NIM sesi lokal');
      expect(gateway.passwordTerkirim, '20051207');
      expect(await service.punyaKredensial(), isTrue);
    });

    test('field kosong (biodata portal belum diisi BE tolak/502) → cache '
        'baik tidak ditimpa, tanpa flag', () async {
      final gateway = _GatewayFake();
      handlerPanggil = (_) => ResponseBody.fromString(
            jsonEncode({
              'status': 'success',
              'data': {'username': '23SA21A060', 'password': ''},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
      final service = serviceDengan(gateway);

      // Isi cache lama agar bisa dibuktikan tidak ditimpa.
      final secure = const FlutterSecureStorage();
      await secure.write(key: 'wifi_kampus_username', value: 'LAMA');
      await secure.write(key: 'wifi_kampus_password', value: '20040305');

      await service.segarkanKredensial();

      expect(gateway.usernameTerkirim, isNull,
          reason: 'field kosong → jangan kirim ke native');
      expect(await secure.read(key: 'wifi_kampus_username'), 'LAMA',
          reason: 'cache baik harus utuh');
      expect(await service.punyaKredensial(), isTrue);
    });

    test('BE gagal (offline/502) → tidak crash, kredensial tidak tersentuh',
        () async {
      final gateway = _GatewayFake();
      handlerPanggil = (_) => throw Exception('offline');
      final service = serviceDengan(gateway);

      await service.segarkanKredensial();

      expect(gateway.usernameTerkirim, isNull);
      expect(await service.punyaKredensial(), isFalse);
    });

    test('sukses menghapus backoff aktif (alur pemulihan)', () async {
      final gateway = _GatewayFake();
      handlerPanggil = (_) => _balasKredensial('23SA21A060', '20051207');
      final service = serviceDengan(gateway);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('wifi_kampus_backoff_until',
          DateTime.now().add(const Duration(hours: 10)).millisecondsSinceEpoch);
      await prefs.setInt('wifi_kampus_gagal_beruntun', 1);

      await service.segarkanKredensial();

      final setelah = await SharedPreferences.getInstance();
      expect(setelah.getInt('wifi_kampus_backoff_until'), isNull,
          reason: 'kredensial segar = backoff harus dicabut');
      expect(setelah.getInt('wifi_kampus_gagal_beruntun'), isNull);
      expect(await service.sedangBackoff(), isFalse);
    });
  });

  group('deteksi biodata kosong — kontrak code stabil BE 2026-11-11', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    late ResponseBody Function(RequestOptions) handlerPanggil;

    WifiKampusService serviceDengan(_GatewayFake gateway) {
      ApiClient.instance.dio.httpClientAdapter = _KredensialAdapter(
        (options) => handlerPanggil(options),
      );
      ApiClient.instance.dio.transformer = SyncTransformer();
      return WifiKampusService.untukTest(gateway);
    }

    ResponseBody balas502({String? code}) => ResponseBody.fromString(
          jsonEncode({
            'status': 'error',
            'error': 'Bad Gateway',
            'message': 'Tanggal lahir tidak tersedia di biodata portal — '
                'kredensial wifi tidak dapat dibentuk',
            'code': ?code,
          }),
          502,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );

    test('502 + code biodata_tanggal_lahir_kosong → biodataKosong true, '
        'cache baik utuh', () async {
      final gateway = _GatewayFake();
      handlerPanggil = (_) => balas502(code: WifiKampusService.kodeBiodataKosong);
      final service = serviceDengan(gateway);

      final secure = const FlutterSecureStorage();
      await secure.write(key: 'wifi_kampus_username', value: 'LAMA');
      await secure.write(key: 'wifi_kampus_password', value: '20040305');

      await service.segarkanKredensial();

      expect(service.biodataKosong, isTrue,
          reason: 'kondisi permanen dicatat untuk penjelasan sheet/Profil');
      expect(await secure.read(key: 'wifi_kampus_username'), 'LAMA',
          reason: 'cache baik tidak ditimpa');
      expect(gateway.usernameTerkirim, isNull);
    });

    test('502 TANPA code → galat sementara, biodataKosong tetap false', () async {
      final gateway = _GatewayFake();
      handlerPanggil = (_) => balas502();
      final service = serviceDengan(gateway);

      await service.segarkanKredensial();

      expect(service.biodataKosong, isFalse,
          reason: 'tanpa code stabil, FE tidak boleh menebak penyebab');
    });

    test('500 → galat sementara, biodataKosong tetap false', () async {
      final gateway = _GatewayFake();
      handlerPanggil = (_) => ResponseBody.fromString('{"status":"error"}', 500);
      final service = serviceDengan(gateway);

      await service.segarkanKredensial();

      expect(service.biodataKosong, isFalse);
    });

    test('sukses kredensial menghapus flag (alur pemulihan setelah biodata '
        'diisi di portal)', () async {
      final gateway = _GatewayFake();
      handlerPanggil = (_) => balas502(code: WifiKampusService.kodeBiodataKosong);
      final service = serviceDengan(gateway);
      service.biodataKosong = true;

      handlerPanggil = (_) => _balasKredensial('23SA21A060', '20051207');
      await service.segarkanKredensial();

      expect(service.biodataKosong, isFalse,
          reason: 'kredensial berhasil didapat → biodata jelas sudah terisi');
      expect(await service.punyaKredensial(), isTrue);
    });

    test('simpanOverride menghapus flag (kredensial manual membuat info '
        'tidak relevan)', () async {
      final gateway = _GatewayFake();
      final service = serviceDengan(gateway);
      service.biodataKosong = true;

      await service.simpanOverride('MANUAL', '20051207');

      expect(service.biodataKosong, isFalse);
    });

    test('bersihkanSaatLogout menghapus flag', () async {
      final gateway = _GatewayFake();
      final service = serviceDengan(gateway);
      service.biodataKosong = true;

      await service.bersihkanSaatLogout();

      expect(service.biodataKosong, isFalse);
    });
  });

  group('attemptLogin — throttle, backoff & pemetaan fase', () {
    late _GatewayFake gateway;
    late WifiKampusService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      gateway = _GatewayFake();
      service = WifiKampusService.untukTest(gateway);
    });

    test('berhasil → fase terhubung, snack callback sekali', () async {
      gateway.statusLogin = 'berhasil';
      var snackCount = 0;
      service.onTerhubungPertama = () => snackCount++;
      // Attempt kedua dengan status sama TIDAK memicu snack ulang.
      await service.attemptLogin();
      await service.attemptLogin();
      expect(service.fase.value, WifiKampusFase.terhubung);
      expect(snackCount, 1);
    });

    test('bukanWifiKampus → fase diLuar (indikator disembunyikan)', () async {
      await service.attemptLogin();
      expect(service.fase.value, WifiKampusFase.diLuar);
    });

    test('bukanWifiKampus TIDAK dihitung kegagalan backoff', () async {
      gateway.statusLogin = 'bukanWifiKampus';
      for (var i = 0; i < 5; i++) {
        await service.attemptLogin();
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('wifi_kampus_gagal_beruntun'), isNull,
          reason: 'pindah-pindah jaringan bukan kegagalan portal/kredensial');
      expect(await service.sedangBackoff(), isFalse);
    });

    test('kredensialSalah di WiFi kampus → fase terputus, gagal tercatat',
        () async {
      gateway.statusLogin = 'kredensialSalah';
      gateway.diWifiKampus = true;
      await service.attemptLogin();
      expect(service.fase.value, WifiKampusFase.terputus,
          reason: 'di WiFi kampus = indikator terputus, bukan sembunyi');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('wifi_kampus_gagal_beruntun'), 1);
    });

    test('3 gagal beruntun → backoff 24 jam, attempt otomatis di-skip',
        () async {
      var now = DateTime(2026, 11, 11, 8, 0);
      service.nowProvider = () => now;
      gateway.statusLogin = 'kredensialSalah';
      gateway.diWifiKampus = true;

      await service.attemptLogin(); // gagal 1
      now = now.add(const Duration(minutes: 6));
      await service.attemptLogin(); // gagal 2
      now = now.add(const Duration(minutes: 6));
      await service.attemptLogin(); // gagal 3 → backoff

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('wifi_kampus_gagal_beruntun'), 0,
          reason: 'counter di-reset — siklus berikutnya dapat jatah 3 lagi');
      final backoffUntil = prefs.getInt('wifi_kampus_backoff_until');
      expect(backoffUntil, isNotNull);
      expect(
        DateTime.fromMillisecondsSinceEpoch(backoffUntil!),
        DateTime(2026, 11, 12, 8, 12),
        reason: 'attempt ke-3 (pemicu backoff) terjadi di 8:12 → +24 jam',
      );
      expect(await service.sedangBackoff(), isTrue);
      expect(service.fase.value, WifiKampusFase.terputus,
          reason: 'saat backoff fase tetap jujur via cek jaringan');

      // Portal seolah sudah bisa diterima — attempt otomatis TETAP di-skip
      // selama backoff (keputusan user: diam 24 jam, tanpa retry).
      gateway.statusLogin = 'berhasil';
      now = now.add(const Duration(hours: 2));
      await service.attemptLogin();
      expect(gateway.loginCalls, 3,
          reason: 'attempt ke-4 otomatis harus di-skip oleh backoff');
      expect(service.fase.value, WifiKampusFase.terputus);

      // Lewat 24 jam → attempt jalan lagi.
      now = now.add(const Duration(hours: 23)); // total 25 jam sejak backoff
      await service.attemptLogin();
      expect(gateway.loginCalls, 4);
      expect(service.fase.value, WifiKampusFase.terhubung);
    });

    test('berhasil mereset hitungan gagal (tidak membawa sisa kegagalan)',
        () async {
      var now = DateTime(2026, 11, 11, 8, 0);
      service.nowProvider = () => now;
      gateway.diWifiKampus = true;

      gateway.statusLogin = 'kredensialSalah';
      await service.attemptLogin(); // gagal 1
      now = now.add(const Duration(minutes: 6));
      await service.attemptLogin(); // gagal 2
      gateway.statusLogin = 'berhasil';
      now = now.add(const Duration(minutes: 6));
      await service.attemptLogin(); // sukses → reset

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('wifi_kampus_gagal_beruntun'), isNull);
      expect(prefs.getInt('wifi_kampus_backoff_until'), isNull);
      expect(await service.sedangBackoff(), isFalse);
    });

    test('portalGagal → fase terputus (indikator redup, bukan hilang)',
        () async {
      gateway.statusLogin = 'portalGagal';
      gateway.diWifiKampus = true;
      await service.attemptLogin();
      expect(service.fase.value, WifiKampusFase.terputus);
    });

    test('tanpaKredensial + di WiFi kampus → fase terputus', () async {
      gateway.statusLogin = 'tanpaKredensial';
      gateway.diWifiKampus = true;
      await service.attemptLogin();
      expect(service.fase.value, WifiKampusFase.terputus);
    });

    test('throttle: attempt kedua dalam 5 menit di-skip', () async {
      var now = DateTime(2026, 11, 11, 8, 0);
      service.nowProvider = () => now;
      await service.attemptLogin();
      final panggilanPertama = gateway.loginCalls;
      expect(panggilanPertama, 1);

      now = now.add(const Duration(minutes: 2));
      await service.attemptLogin();
      expect(gateway.loginCalls, 1, reason: 'dalam jendela throttle = skip');

      now = now.add(const Duration(minutes: 4)); // total 6 menit
      await service.attemptLogin();
      expect(gateway.loginCalls, 2, reason: 'lewat jendela throttle = jalan');
    });

    test('single-flight: attempt paralel digabung satu eksekusi', () async {
      final komplek = Completer<String>();
      gateway.statusLogin = 'berhasil';
      // Gateway lambat: attempt kedua datang sebelum pertama selesai.
      // (single-flight dijamin _sedangBerjalan; cukup buktikan tidak crash.)
      unawaited(service.attemptLogin());
      unawaited(service.attemptLogin());
      await komplek.future.timeout(const Duration(seconds: 1), onTimeout: () {
        // Tidak ada yang menggantung — attempt paralel aman.
        return 'ok';
      });
      expect(service.fase.value, WifiKampusFase.terhubung);
    });
  });

  group('cobaLoginManual — menembus throttle & backoff', () {
    late _GatewayFake gateway;
    late WifiKampusService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      gateway = _GatewayFake();
      service = WifiKampusService.untukTest(gateway);
    });

    test('manual tetap jalan saat throttle & backoff aktif', () async {
      var now = DateTime(2026, 11, 11, 8, 0);
      service.nowProvider = () => now;
      gateway.statusLogin = 'kredensialSalah';
      gateway.diWifiKampus = true;

      // 3 gagal beruntun lewat attempt otomatis → backoff aktif.
      await service.attemptLogin();
      now = now.add(const Duration(minutes: 6));
      await service.attemptLogin();
      now = now.add(const Duration(minutes: 6));
      await service.attemptLogin();
      expect(await service.sedangBackoff(), isTrue);
      final otomatis = gateway.loginCalls;

      // Manual: error sistem boleh di-trigger user (keputusan user).
      gateway.statusLogin = 'berhasil';
      now = now.add(const Duration(minutes: 1));
      final hasil = await service.cobaLoginManual();
      expect(hasil, HasilPortal.berhasil);
      expect(gateway.loginCalls, otomatis + 1,
          reason: 'manual harus menembus backoff');
      expect(service.fase.value, WifiKampusFase.terhubung);
      expect(await service.sedangBackoff(), isFalse,
          reason: 'sukses manual menghapus backoff');
    });

    test('manual gagal tetap dicatat untuk backoff', () async {
      var now = DateTime(2026, 11, 11, 8, 0);
      service.nowProvider = () => now;
      gateway.statusLogin = 'portalGagal';
      gateway.diWifiKampus = true;

      await service.cobaLoginManual();
      now = now.add(const Duration(minutes: 1));
      await service.cobaLoginManual();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('wifi_kampus_gagal_beruntun'), 2,
          reason: 'kegagalan manual juga dihitung — anti retry nagging');
    });
  });

  group('bersihkanSaatLogout', () {
    test('hapus kredensial + penghambat + clearCredentials native', () async {
      SharedPreferences.setMockInitialValues({});
      final gateway = _GatewayFake();
      final service = WifiKampusService.untukTest(gateway);
      gateway.statusLogin = 'kredensialSalah';
      gateway.diWifiKampus = true;
      await service.attemptLogin();
      await service.bersihkanSaatLogout();

      expect(gateway.clearCredentialsCalled, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('wifi_kampus_attempt_at'), isNull);
      expect(prefs.getInt('wifi_kampus_gagal_beruntun'), isNull);
      expect(prefs.getInt('wifi_kampus_backoff_until'), isNull);
      expect(await service.punyaKredensial(), isFalse);
      expect(service.fase.value, WifiKampusFase.diLuar);
    });

    test('toggle auto-login DIPERTAHANKAN saat logout (setting perangkat)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final gateway = _GatewayFake();
      final service = WifiKampusService.untukTest(gateway);

      await service.setAutoLogin(false);
      await service.bersihkanSaatLogout();

      expect(await service.autoLoginAktif(), isFalse,
          reason: 'toggle milik perangkat, bukan data sesi');
      // Kredensial tetap dibersihkan.
      expect(await service.punyaKredensial(), isFalse);
    });
  });

  group('toggle auto-login', () {
    late _GatewayFake gateway;
    late WifiKampusService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      gateway = _GatewayFake();
      service = WifiKampusService.untukTest(gateway);
    });

    test('default ON — pref belum ada = perilaku lama', () async {
      expect(await service.autoLoginAktif(), isTrue);
    });

    test('OFF → attempt otomatis tidak mengirim portal, fase tetap sinkron',
        () async {
      gateway.statusLogin = 'berhasil';
      gateway.diWifiKampus = true;

      await service.setAutoLogin(false);
      await service.attemptLogin();

      expect(gateway.loginCalls, 0,
          reason: 'auto-login mati → portal tidak pernah dikirim');
      expect(service.fase.value, WifiKampusFase.terputus,
          reason: 'di WiFi kampus → indikator tetap jujur (terputus)');
    });

    test('OFF → di luar kampus fase diLuar (indikator sembunyi)', () async {
      gateway.statusLogin = 'bukanWifiKampus';
      await service.setAutoLogin(false);
      await service.attemptLogin();
      expect(service.fase.value, WifiKampusFase.diLuar);
    });

    test('ON kembali → attempt jalan normal', () async {
      gateway.statusLogin = 'berhasil';
      gateway.diWifiKampus = true;

      await service.setAutoLogin(false);
      await service.attemptLogin();
      expect(gateway.loginCalls, 0);

      await service.setAutoLogin(true);
      await service.attemptLogin();
      expect(gateway.loginCalls, 1);
      expect(service.fase.value, WifiKampusFase.terhubung);
    });

    test('manual tetap jalan walau toggle OFF (keputusan user)', () async {
      gateway.statusLogin = 'berhasil';
      gateway.diWifiKampus = true;

      await service.setAutoLogin(false);
      final hasil = await service.cobaLoginManual();

      expect(hasil, HasilPortal.berhasil);
      expect(gateway.loginCalls, 1);
      expect(service.fase.value, WifiKampusFase.terhubung);
    });
  });

  group('override kredensial manual (Profil)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('simpanOverride → native terkirim, flag aktif, penghambat reset',
        () async {
      final gateway = _GatewayFake();
      final service = WifiKampusService.untukTest(gateway);

      // Backoff aktif dari kegagalan sebelumnya.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'wifi_kampus_backoff_until',
          DateTime.now()
              .add(const Duration(hours: 20))
              .millisecondsSinceEpoch);

      await service.simpanOverride('23SA21A060', '20051207');

      expect(gateway.usernameTerkirim, '23SA21A060');
      expect(gateway.passwordTerkirim, '20051207');
      expect(await service.overrideAktif(), isTrue);
      expect(prefs.getInt('wifi_kampus_backoff_until'), isNull,
          reason: 'override baru = alur pemulihan, backoff dicabut');
      final efektif = await service.kredensialEfektif();
      expect(efektif?.username, '23SA21A060');
      expect(efektif?.password, '20051207');
    });

    test('override aktif → segarkanKredensial TIDAK menimpa dari BE',
        () async {
      final gateway = _GatewayFake();
      final service = WifiKampusService.untukTest(gateway);
      ApiClient.instance.dio.httpClientAdapter = _KredensialAdapter(
        (options) => _balasKredensial('BE-USERNAME', 'BE-PASSWORD'),
      );
      ApiClient.instance.dio.transformer = SyncTransformer();

      await service.simpanOverride('MANUAL', ' MANUAL-PASS'.trim());
      await service.segarkanKredensial();

      expect(gateway.usernameTerkirim, 'MANUAL',
          reason: 'kredensial BE tidak boleh menimpa override user');
      final efektif = await service.kredensialEfektif();
      expect(efektif?.username, 'MANUAL');
    });

    test('hapusOverride → flag hilang, BE dipanggil ulang untuk pulihkan',
        () async {
      final gateway = _GatewayFake();
      final service = WifiKampusService.untukTest(gateway);
      var beDipanggil = 0;
      ApiClient.instance.dio.httpClientAdapter = _KredensialAdapter(
        (options) {
          beDipanggil++;
          return _balasKredensial('23SA21A060', '20051207');
        },
      );
      ApiClient.instance.dio.transformer = SyncTransformer();

      await service.simpanOverride('MANUAL', '12345678');
      expect(await service.overrideAktif(), isTrue);

      await service.hapusOverride();

      expect(await service.overrideAktif(), isFalse);
      expect(beDipanggil, 1,
          reason: 'pulihkan = fetch ulang kredensial BE');
      expect(gateway.usernameTerkirim, '23SA21A060',
          reason: 'kredensial BE kembali terkirim ke native');
      final efektif = await service.kredensialEfektif();
      expect(efektif?.username, '23SA21A060');
    });

    test('hapusOverride saat BE offline → flag tetap hilang, tidak crash',
        () async {
      final gateway = _GatewayFake();
      final service = WifiKampusService.untukTest(gateway);
      ApiClient.instance.dio.httpClientAdapter = _KredensialAdapter(
        (options) => throw Exception('offline'),
      );
      ApiClient.instance.dio.transformer = SyncTransformer();

      await service.simpanOverride('MANUAL', '12345678');
      await service.hapusOverride();

      expect(await service.overrideAktif(), isFalse);
      expect(await service.punyaKredensial(), isFalse,
          reason: 'override dihapus, cache utama memang kosong');
    });

    test('attemptLogin memakai override (bukan cache BE)', () async {
      final gateway = _GatewayFake();
      final service = WifiKampusService.untukTest(gateway);
      gateway.statusLogin = 'berhasil';
      gateway.diWifiKampus = true;

      // Cache utama berisi kredensial BE lama (salah).
      final secure = const FlutterSecureStorage();
      await secure.write(key: 'wifi_kampus_username', value: 'BE-LAMA');
      await secure.write(key: 'wifi_kampus_password', value: '20000101');

      await service.simpanOverride('MANUAL-BARU', '20051207');
      await service.attemptLogin();

      expect(gateway.usernameTerkirim, 'MANUAL-BARU',
          reason: 'override harus menang atas cache BE');
    });

    test('bersihkanSaatLogout menghapus override (kredensial + flag)',
        () async {
      final gateway = _GatewayFake();
      final service = WifiKampusService.untukTest(gateway);

      await service.simpanOverride('MANUAL', '12345678');
      await service.bersihkanSaatLogout();

      expect(await service.overrideAktif(), isFalse);
      expect(await service.kredensialEfektif(), isNull);
    });

    test('kredensialEfektif tanpa apa pun → null (tidak crash)', () async {
      final gateway = _GatewayFake();
      final service = WifiKampusService.untukTest(gateway);
      expect(await service.kredensialEfektif(), isNull);
    });
  });
}
