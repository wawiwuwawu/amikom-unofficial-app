// Test Fase 2b: panduan anti-pembunuhan-proses OEM (dontkillmyapp.com) di
// halaman Notifikasi — kartu kecil + sheet langkah per merek.
//
// Pola mocking mengikuti lazy_list_smoke_test.dart (FakeAdapter di atas dio)
// untuk test level halaman, dan mock MethodChannel device_info_plus
// (`getDeviceInfo`) untuk deteksi merek. TargetPlatform default di
// flutter_test sudah Android, jadi deteksi lewat defaultTargetPlatform
// langsung aktif tanpa override.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/pages/notifikasi_list_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/oem_baterai_service.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/widgets/oem_panduan_sheet.dart';

const _kChannelDeviceInfo = MethodChannel(
  'dev.fluttercommunity.plus/device_info',
);

/// Map AndroidDeviceInfo LENGKAP — fromMap device_info_plus membaca semua
/// kunci tanpa fallback (null → runtime type error di field non-nullable).
Map<String, dynamic> _androidDeviceInfoMap({
  required String manufacturer,
  required String model,
}) =>
    {
      'version': {
        'baseOS': null,
        'sdkInt': 34,
        'release': '14',
        'codename': 'REL',
        'incremental': 'build',
        'previewSdkInt': null,
        'securityPatch': '2026-01-05',
      },
      'board': 'board',
      'bootloader': 'bootloader',
      'brand': manufacturer,
      'device': 'device',
      'display': 'display',
      'fingerprint': 'fingerprint',
      'hardware': 'hardware',
      'host': 'host',
      'id': 'id',
      'manufacturer': manufacturer,
      'model': model,
      'product': 'product',
      'name': 'name',
      'supported32BitAbis': <String>[],
      'supported64BitAbis': <String>[],
      'supportedAbis': <String>['arm64-v8a'],
      'tags': 'release-keys',
      'type': 'user',
      'isPhysicalDevice': true,
      'freeDiskSize': 1,
      'totalDiskSize': 2,
      'systemFeatures': <String>[],
      'isLowRamDevice': false,
      'physicalRamSize': 8192,
      'availableRamSize': 4096,
    };

class _FakeAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions)> handlers;

  _FakeAdapter(this.handlers);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    for (final entry in handlers.entries) {
      if (options.path.contains(entry.key)) return entry.value(options);
    }
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> payload) => ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.dio.transformer = SyncTransformer();
  });

  tearDown(() {
    // Reset mock channel device_info supaya test lain mulai bersih.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_kChannelDeviceInfo, null);
  });

  void mockMerek(String manufacturer, String model) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_kChannelDeviceInfo, (call) async {
      if (call.method != 'getDeviceInfo') return null;
      return _androidDeviceInfoMap(manufacturer: manufacturer, model: model);
    });
  }

  group('OemBateraiService.klasifikasi — normalisasi merek', () {
    test('xiaomi/redmi/poco → Xiaomi', () {
      final a = OemBateraiService.klasifikasi('Xiaomi', 'POCO X5');
      expect(a.merek, OemMerek.xiaomi);
      expect(a.label, 'Xiaomi');

      final b = OemBateraiService.klasifikasi('Xiaomi', 'Redmi Note 12');
      expect(b.merek, OemMerek.xiaomi);
    });

    test('oppo/realme/oneplus → kelompok Oppo dengan label sendiri', () {
      expect(
        OemBateraiService.klasifikasi('OPPO', 'CPH2451').merek,
        OemMerek.oppo,
      );
      final realme = OemBateraiService.klasifikasi('realme', 'RMX3771');
      expect(realme.merek, OemMerek.oppo);
      expect(realme.label, 'Realme');
      final oneplus = OemBateraiService.klasifikasi('OnePlus', 'CPH2413');
      expect(oneplus.merek, OemMerek.oppo);
      expect(oneplus.label, 'OnePlus');
    });

    test('vivo/iqoo → Vivo', () {
      expect(
        OemBateraiService.klasifikasi('vivo', 'iQOO Z7').merek,
        OemMerek.vivo,
      );
      expect(
        OemBateraiService.klasifikasi('vivo', 'V2312').label,
        'Vivo',
      );
    });

    test('samsung → Samsung', () {
      final s = OemBateraiService.klasifikasi('samsung', 'SM-S921B');
      expect(s.merek, OemMerek.samsung);
      expect(s.label, 'Samsung');
    });

    test('infinix/tecno/itel → kelompok Infinix/Tecno', () {
      expect(
        OemBateraiService.klasifikasi('INFINIX', 'X6831').merek,
        OemMerek.infinix,
      );
      expect(
        OemBateraiService.klasifikasi('TECNO', 'CK7n').merek,
        OemMerek.infinix,
      );
      expect(
        OemBateraiService.klasifikasi('itel', 'A662L').merek,
        OemMerek.infinix,
      );
    });

    test('huawei/honor → Huawei', () {
      expect(
        OemBateraiService.klasifikasi('HUAWEI', 'VOG-L29').merek,
        OemMerek.huawei,
      );
      expect(
        OemBateraiService.klasifikasi('HONOR', 'ANY-LX1').merek,
        OemMerek.huawei,
      );
    });

    test('merek tak dikenal → generik tanpa label', () {
      final g = OemBateraiService.klasifikasi('Google', 'Pixel 8');
      expect(g.merek, OemMerek.generik);
      expect(g.label, isNull);
    });
  });

  group('OemBateraiService.deteksiMerek — fail-open', () {
    test('membaca Build.MANUFACTURER via channel', () async {
      mockMerek('samsung', 'SM-A155F');
      final info = await OemBateraiService.deteksiMerek();
      expect(info.merek, OemMerek.samsung);
    });

    test('channel gagal → generik (kartu tetap tampil versi generik)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_kChannelDeviceInfo, (call) async {
        throw PlatformException(code: 'error', message: 'boom');
      });
      final info = await OemBateraiService.deteksiMerek();
      expect(info.merek, OemMerek.generik);
    });

    test('platform non-Android → generik', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      mockMerek('samsung', 'SM-A155F');
      final info = await OemBateraiService.deteksiMerek();
      expect(info.merek, OemMerek.generik);
    });
  });

  group('Kartu panduan di NotifikasiListPage', () {
    testWidgets('tampil dengan merek terdeteksi & bisa ditutup (prefs)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      mockMerek('Xiaomi', '23013PC75G');
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter({
        '/api/v1/notifikasi/optin': (_) => _json({
              'status': 'success',
              'data': {'enabled': false, 'token_count': 0},
            }),
        '/api/v1/notifikasi': (_) => _json({
              'status': 'success',
              'data': [
                {'id': 'n1', 'judul': 'Notifikasi Uji', 'tanggal': '24-10-2026'},
              ],
            }),
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const NotifikasiListPage(),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Kartu tampil antara push card dan daftar (varian normal, index-0).
      expect(find.textContaining('HP Xiaomi punya pembatas khusus'),
          findsOneWidget);
      expect(find.text('Lihat panduan'), findsOneWidget);

      // Tutup kartu → prefs oem_panduan_ditutup = true, kartu hilang.
      await tester.tap(find.byIcon(CupertinoIcons.xmark));
      await tester.pumpAndSettle();
      expect(find.textContaining('punya pembatas khusus'), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('oem_panduan_ditutup'), isTrue);
    });

    testWidgets('tidak tampil lagi bila user sudah pernah menutup', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'oem_panduan_ditutup': true});
      mockMerek('Xiaomi', '23013PC75G');
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter({
        '/api/v1/notifikasi/optin': (_) => _json({
              'status': 'success',
              'data': {'enabled': false, 'token_count': 0},
            }),
        '/api/v1/notifikasi': (_) => _json({
              'status': 'success',
              'data': [
                {'id': 'n1', 'judul': 'Notifikasi Uji', 'tanggal': '24-10-2026'},
              ],
            }),
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const NotifikasiListPage(),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(find.textContaining('punya pembatas khusus'), findsNothing);
      expect(find.text('Lihat panduan'), findsNothing);
    });

    testWidgets('merek tak dikenal tampil versi generik', (tester) async {
      SharedPreferences.setMockInitialValues({});
      mockMerek('Google', 'Pixel 8');
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter({
        '/api/v1/notifikasi/optin': (_) => _json({
              'status': 'success',
              'data': {'enabled': false, 'token_count': 0},
            }),
        '/api/v1/notifikasi': (_) => _json({
              'status': 'success',
              'data': [
                {'id': 'n1', 'judul': 'Notifikasi Uji', 'tanggal': '24-10-2026'},
              ],
            }),
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const NotifikasiListPage(),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(find.textContaining('Banyak HP membatasi notifikasi'),
          findsOneWidget);
      expect(find.textContaining('punya pembatas khusus'), findsNothing);
    });
  });

  group('OemPanduanSheet — langkah spesifik per merek', () {
    testWidgets('Xiaomi: Autostart + No restrictions, bukan langkah generik', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SingleChildScrollView(
            child: OemPanduanSheet(
              merek: OemMerekInfo(OemMerek.xiaomi, label: 'Xiaomi'),
            ),
          ),
        ),
      );

      expect(
        find.text('Biar notifikasi & pengingat selalu muncul — Xiaomi'),
        findsOneWidget,
      );
      expect(find.text('Aktifkan Autostart'), findsOneWidget);
      expect(find.textContaining('No restrictions'), findsOneWidget);
      expect(find.text('Kunci di layar recents'), findsOneWidget);
      // Langkah generik TIDAK ikut tampil.
      expect(
        find.text('Izinkan autostart bila tersedia'),
        findsNothing,
      );
      expect(find.text('Tambahkan ke Never sleeping apps'), findsNothing);
      // Catatan bawah sheet selalu ada.
      expect(find.textContaining('jangan Force stop'), findsOneWidget);
    });

    testWidgets('Samsung: Never sleeping apps kritis muncul', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SingleChildScrollView(
            child: OemPanduanSheet(
              merek: OemMerekInfo(OemMerek.samsung, label: 'Samsung'),
            ),
          ),
        ),
      );

      expect(
        find.text('Biar notifikasi & pengingat selalu muncul — Samsung'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Never sleeping apps'),
        findsNWidgets(2),
        reason: 'judul langkah + detail (app "ditidurkan" ±3 hari)',
      );
      expect(find.textContaining('Put unused apps to sleep'), findsOneWidget);
      // Langkah Xiaomi TIDAK ikut tampil.
      expect(find.textContaining('No restrictions'), findsNothing);
    });

    testWidgets('merek tak dikenal: langkah generik', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SingleChildScrollView(
            child: OemPanduanSheet(merek: OemMerekInfo.generik()),
          ),
        ),
      );

      expect(
        find.text('Biar notifikasi & pengingat selalu muncul'),
        findsOneWidget,
        reason: 'judul generik tanpa label merek',
      );
      expect(find.text('Izinkan autostart bila tersedia'), findsOneWidget);
      expect(find.textContaining("Don't optimize"), findsOneWidget);
      expect(find.textContaining('No restrictions'), findsNothing);
      expect(find.textContaining('Never sleeping apps'), findsNothing);
    });

    testWidgets('setiap langkah ber-setting punya tombol Buka setelan', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SingleChildScrollView(
            child: OemPanduanSheet(
              merek: OemMerekInfo(OemMerek.samsung, label: 'Samsung'),
            ),
          ),
        ),
      );

      // Ketiga langkah Samsung punya target setelan.
      expect(find.text('Buka setelan'), findsNWidgets(3));
    });
  });
}
