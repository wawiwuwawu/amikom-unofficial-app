// Regresi trigger auto-login WiFi di splash (keputusan user 2026-11-12):
//  - Attempt portal dijalankan SEBELUM health check — user yang menyambungkan
//    Hotspot@Amikom lalu membuka app langsung ter-login portal (internet
//    nyala) tanpa pernah melihat "periksa jaringan Anda".
//  - Sudah online / di luar kampus / toggle OFF → tanpa POST portal, alur
//    splash tetap jalan normal.
//  - Portal gagal → splash tetap lanjut ke health check (fail-open).
//  - Tombol "Coba Lagi" di error screen memakai jalur manual (menembus
//    throttle & backoff) sebelum mengecek ulang sesi.
//
// Splash TIDAK menampilkan hasil attempt — cukup lewat fase/indikator.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/pages/splash_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/wifi_kampus_service.dart';

class _GatewayFake implements WifiKampusGateway {
  _GatewayFake(this.urutan);

  /// Log urutan kejadian bersama dengan adapter Dio (audit "attempt portal
  /// SEBELUM health check").
  final List<String> urutan;

  String statusLogin = 'berhasil';
  bool diWifiKampus = false;
  int loginCalls = 0;
  int manualCalls = 0;

  @override
  Future<void> setCredentials(String username, String password) async {}

  @override
  Future<void> clearCredentials() async {}

  @override
  Future<String> loginIfConnected() async {
    loginCalls++;
    urutan.add('portal-attempt');
    return statusLogin;
  }

  @override
  Future<Map<String, dynamic>> statusJaringan() async => {
        'diWifiKampus': diWifiKampus,
        'ssidTerbaca': true,
        'portalTerjangkau': true,
        'online': diWifiKampus,
      };

  @override
  void onWifiUp(void Function() callback) {}

  @override
  void mintaIzinSsidSetelahGranted(void Function() callback) {}

  @override
  Future<bool> mintaIzinSsid() async => true;
}

/// Adapter Dio palsu: /health dan /api/v1/dashboard. Endpoint lain = gagal
/// cepat agar salah kabel langsung terlihat di test.
class _SplashAdapter implements HttpClientAdapter {
  _SplashAdapter(this.urutan, {this.healthGagal = false});

  final List<String> urutan;
  final bool healthGagal;
  int healthRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    urutan.add(options.path);
    if (options.path.contains('/health')) {
      healthRequests++;
      if (healthGagal) {
        return ResponseBody.fromString('{"status":"error"}', 500,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            });
      }
      return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          });
    }
    if (options.path.contains('/api/v1/dashboard')) {
      return ResponseBody.fromString(
        jsonEncode({
          'status': 'success',
          'data': {'profile': {}},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    throw Exception('endpoint tak dikenal: ${options.path}');
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> pompa(
    WidgetTester tester, {
    required _GatewayFake gateway,
    required _SplashAdapter adapter,
    bool autoLogin = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'wifi_kampus_auto_login': autoLogin,
    });
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.dio.httpClientAdapter = adapter;
    ApiClient.instance.dio.transformer = SyncTransformer();
    await tester.pumpWidget(MaterialApp(
      routes: {
        '/login': (_) => const Scaffold(body: SizedBox()),
        '/main': (_) => const Scaffold(body: SizedBox()),
      },
      home: SplashPage(wifiKampus: WifiKampusService.untukTest(gateway)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('attempt portal dijalankan SEBELUM health check', (tester) async {
    final urutan = <String>[];
    final gateway = _GatewayFake(urutan);
    final adapter = _SplashAdapter(urutan);
    await pompa(tester, gateway: gateway, adapter: adapter);

    expect(gateway.loginCalls, 1,
        reason: 'splash memicu satu attempt portal');
    expect(urutan.first, 'portal-attempt',
        reason: 'portal harus di-nembak SEBELUM health check — '
            'internet baru nyala setelah login portal');
    expect(urutan, contains('/health'));
  });

  testWidgets('portal gagal (kredensial salah) → splash tetap lanjut ke '
      'health check (fail-open)', (tester) async {
    final urutan = <String>[];
    final gateway = _GatewayFake(urutan);
    gateway.statusLogin = 'kredensialSalah';
    gateway.diWifiKampus = true;
    final adapter = _SplashAdapter(urutan);
    await pompa(tester, gateway: gateway, adapter: adapter);

    expect(gateway.loginCalls, 1);
    expect(urutan, contains('/health'),
        reason: 'kegagalan portal tidak boleh menggantung startup');
  });

  testWidgets('toggle auto-login OFF → tanpa POST portal, health check tetap '
      'jalan', (tester) async {
    final urutan = <String>[];
    final gateway = _GatewayFake(urutan);
    final adapter = _SplashAdapter(urutan);
    await pompa(tester, gateway: gateway, adapter: adapter, autoLogin: false);

    expect(gateway.loginCalls, 0,
        reason: 'fitur opsional — OFF berarti splash tidak menyentuh portal');
    expect(urutan, contains('/health'));
  });

  testWidgets('tombol Coba Lagi di error screen = jalur manual + cek sesi '
      'ulang', (tester) async {
    final urutan = <String>[];
    final gateway = _GatewayFake(urutan);
    final adapter = _SplashAdapter(urutan, healthGagal: true);
    await pompa(tester, gateway: gateway, adapter: adapter);

    expect(find.text('Coba Lagi'), findsOneWidget);
    final awal = gateway.loginCalls;

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(gateway.loginCalls, greaterThan(awal),
        reason: 'retry user menembus throttle/backoff via jalur manual — '
            'jalan keluar saat user menganggap error sistem');
    expect(adapter.healthRequests, greaterThanOrEqualTo(2),
        reason: 'sesi dicek ulang setelah attempt manual');
  });
}
