// Regresi indikator WiFi kampus di AppBar MainPage.
//
// Dijaga:
//  - Fase diLuar → ikon TIDAK dirender (appbar bersih di luar jaringan kampus).
//  - Fase terputus → ikon tampil; ketuk membuka sheet status.
//  - Fase terhubung → ikon tampil; snack transisi dipicu sekali via callback.
//
// MainPage menyentuh banyak service saat initState — test ini memakai
// WifiKampusService.untukTest (gateway palsu) dan membangun indikator +
// sheet langsung, bukan shell penuh (pola notifikasi_push_card_test.dart).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/services/wifi_kampus_service.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/widgets/wifi_kampus_sheet.dart';

class _GatewayFake implements WifiKampusGateway {
  String statusLogin = 'bukanWifiKampus';
  bool diWifiKampus = false;
  bool online = false;

  @override
  Future<void> setCredentials(String nim, String password) async {}

  @override
  Future<void> clearCredentials() async {}

  @override
  Future<String> loginIfConnected() async => statusLogin;

  @override
  Future<Map<String, dynamic>> statusJaringan() async => {
        'diWifiKampus': diWifiKampus,
        'ssidTerbaca': true,
        'portalTerjangkau': true,
        'online': online,
      };

  @override
  void onWifiUp(void Function() callback) {}

  @override
  void mintaIzinSsidSetelahGranted(void Function() callback) {}

  @override
  Future<bool> mintaIzinSsid() async => true;
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    // Secure storage → mock bawaan plugin (I/O nyata Windows tak konsisten).
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  WifiKampusService serviceDengan(WifiKampusFase fase) {
    final service = WifiKampusService.untukTest(_GatewayFake());
    // Set fase langsung — unit keadaan yang diuji adalah RENDER, bukan alur.
    service.fase.value = fase;
    return service;
  }

  Future<void> pumpIndicator(WidgetTester tester, WifiKampusService service) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          appBar: AppBar(actions: [WifiKampusIndicator(service: service)]),
          body: const SizedBox(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('fase diLuar: ikon disembunyikan (appbar bersih)', (tester) async {
    await pumpIndicator(tester, serviceDengan(WifiKampusFase.diLuar));
    expect(find.byIcon(CupertinoIcons.wifi), findsNothing);
    expect(find.byTooltip('Status WiFi Kampus'), findsNothing);
  });

  testWidgets('fase terputus: ikon wifi tampil dan bisa diketuk', (tester) async {
    await pumpIndicator(tester, serviceDengan(WifiKampusFase.terputus));
    expect(find.byTooltip('Status WiFi Kampus'), findsOneWidget);
    // Ketuk → sheet terbuka.
    await tester.tap(find.byTooltip('Status WiFi Kampus'));
    await tester.pumpAndSettle();
    expect(find.text('WiFi Kampus'), findsOneWidget);
    expect(find.text('Coba login lagi'), findsOneWidget);
  });

  testWidgets('fase terhubung: ikon tampil; snack callback hanya sekali',
      (tester) async {
    final gateway = _GatewayFake();
    gateway.statusLogin = 'berhasil';
    final service = WifiKampusService.untukTest(gateway);
    await service.setAutoLogin(true);
    var snack = 0;
    service.onTerhubungPertama = () => snack++;
    // Transisi nyata lewat attemptLogin — bukan penulisan fase langsung.
    await service.attemptLogin();
    await service.attemptLogin(); // pengulangan tanpa transisi
    expect(snack, 1);
    await pumpIndicator(tester, service);
    expect(find.byTooltip('Status WiFi Kampus'), findsOneWidget);
  });

  testWidgets('sheet: penjelasan fase terputus tampil', (tester) async {
    final service = serviceDengan(WifiKampusFase.terputus);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: WifiKampusSheet(service: service)),
      ),
    );
    await tester.pump();
    expect(find.text('Belum terhubung ke internet kampus'), findsOneWidget);
    expect(
      find.textContaining('portal belum menerima login'),
      findsOneWidget,
    );
  });

  testWidgets('sheet: biodataKosong → penjelasan menyebut biodata portal & '
      'kredensial manual', (tester) async {
    final service = serviceDengan(WifiKampusFase.terputus);
    service.biodataKosong = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: WifiKampusSheet(service: service)),
      ),
    );
    await tester.pump();
    expect(
      find.textContaining('biodata portal (tanggal lahir) belum terisi'),
      findsOneWidget,
    );
    expect(find.textContaining('halaman Profil'), findsOneWidget);
    // Penjelasan generik TIDAK boleh ikut tampil (salah satu saja).
    expect(find.textContaining('portal belum menerima login'), findsNothing);
  });

  testWidgets('sheet tombol "Coba login lagi" menjalankan attempt manual',
      (tester) async {
    final gateway = _GatewayFake();
    gateway.statusLogin = 'berhasil';
    final service = WifiKampusService.untukTest(gateway);
    service.fase.value = WifiKampusFase.terputus;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: WifiKampusSheet(service: service)),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Coba login lagi'));
    await tester.pumpAndSettle();
    expect(service.fase.value, WifiKampusFase.terhubung,
        reason: 'hasil manual cukup disampaikan lewat fase/ikon — '
            'keputusan user: tanpa pesan hasil');
  });
}
