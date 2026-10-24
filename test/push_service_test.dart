import 'dart:convert';
import 'dart:typed_data';

import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/deep_link_service.dart';
import 'package:app_amikom/services/navigation_service.dart';
import 'package:app_amikom/services/push_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adapter Dio palsu: halaman daftar notifikasi yang terdorong oleh guard list
/// tetap memanggil jaringan — balas amplop sukses-kosong supaya tidak ada
/// Timer Dio yang masih pending saat test berakhir.
class _FakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'status': 'success', 'data': null}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    // Halaman daftar notifikasi membangun ApiClient yang membaca .env.
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    SharedPreferences.setMockInitialValues({});
  });

  group('PushService.tujuanDariData', () {
    // Keputusan user: SEMUA ketukan membuka halaman daftar notifikasi —
    // tidak ada lagi detail spesifik maupun browser eksternal.
    test('url amikomstudent → buka list (bukan detail)', () {
      expect(
        PushService.tujuanDariData({'url': 'amikomstudent://notifikasi/123'}),
        const AksiBukaList(),
      );
    });

    test('url amikomstudent menang atas notif_id', () {
      expect(
        PushService.tujuanDariData({
          'url': 'amikomstudent://notifikasi/11',
          'notif_id': '22',
        }),
        const AksiBukaList(),
      );
    });

    test('url http/https → buka list, BUKAN browser', () {
      expect(
        PushService.tujuanDariData({'url': 'https://contoh/9'}),
        const AksiBukaList(),
      );
      expect(
        PushService.tujuanDariData({'url': 'http://contoh/9'}),
        const AksiBukaList(),
      );
      expect(
        PushService.tujuanDariData({'url': 'https://x/9', 'notif_id': '77'}),
        const AksiBukaList(),
        reason: 'siaran https tidak jatuh ke notif_id (kontrak BE), '
            'tapi hasilnya tetap list',
      );
    });

    test('tanpa url: fallback notif_id — string maupun angka', () {
      expect(PushService.tujuanDariData({'notif_id': '456'}), const AksiBukaList());
      expect(PushService.tujuanDariData({'notif_id': 456}), const AksiBukaList());
    });

    test('bukan ketukan yang dikenal → null', () {
      expect(
        PushService.tujuanDariData({'url': 'mailto://notifikasi/9'}),
        isNull,
      );
      expect(
        PushService.tujuanDariData({'url': 'amikomstudent://pengumuman/9'}),
        isNull,
      );
      expect(PushService.tujuanDariData({}), isNull);
      expect(PushService.tujuanDariData({'notif_id': '   '}), isNull);
    });
  });

  group('PushService.displayIdDari (id notifikasi tray)', () {
    test('siaran dengan notif_id TIDAK memakai id mentah (hindari tabrakan tray)', () {
      final siaran = PushService.displayIdDari({
        'notif_id': '77',
        'url': 'https://siaran-contoh.test/pengumuman-77',
      });
      final privat = PushService.displayIdDari({
        'notif_id': '77',
        'url': 'amikomstudent://notifikasi/77',
      });

      expect(privat, 77);
      expect(siaran, isNot(77), reason: 'siaran dipatok ke hash url, bukan notif_id');
      expect(
        siaran,
        'https://siaran-contoh.test/pengumuman-77'.hashCode & 0x7fffffff,
      );
    });

    test('siaran tanpa notif_id memakai hash url yang stabil', () {
      const data = {'url': 'https://siaran-contoh.test/stabil'};
      expect(
        PushService.displayIdDari(data),
        PushService.displayIdDari(data),
        reason: 'siaran berulang harus memakai id yang sama agar tidak menumpuk',
      );
    });
  });

  group('PushService dedupe tujuan ketukan', () {
    // Id/url unik per tes: PushService serta DeepLinkService bersifat singleton
    // dan jendela dedupe 2 detik tidak boleh tertabru antar-tes. Antrean
    // pending dibersihkan di tearDown seperti pola
    // test/deep_link_service_test.dart.
    tearDown(() {
      PushService.resetPendingUntukTest();
      DeepLinkService.instance.consumePendingId();
    });

    test('privat: id sama dalam 2 detik hanya diproses sekali', () {
      const data = {'url': 'amikomstudent://notifikasi/9301'};

      expect(
        PushService.instance.resolveTujuan(data),
        const AksiBukaList(),
      );
      expect(
        PushService.instance.resolveTujuan(data),
        isNull,
        reason: 'duplikat dalam 2 detik harus diabaikan',
      );
    });

    test('siaran: url sama dalam 2 detik hanya dibuka sekali', () {
      const data = {'url': 'https://siaran-contoh.test/9302'};

      expect(
        PushService.instance.resolveTujuan(data),
        const AksiBukaList(),
      );
      expect(
        PushService.instance.resolveTujuan(data),
        isNull,
        reason: 'ketukan siaran ganda dalam 2 detik harus diabaikan',
      );
    });

    test('dua siaran berbeda beruntun tetap diproses', () {
      expect(
        PushService.instance.resolveTujuan({'url': 'https://siaran-contoh.test/a'}),
        const AksiBukaList(),
      );
      expect(
        PushService.instance.resolveTujuan({'url': 'https://siaran-contoh.test/b'}),
        const AksiBukaList(),
        reason: 'dedupe siaran tidak boleh menelan url yang berbeda',
      );
    });

    test('siaran tidak mengganggu dedupe privat', () {
      expect(
        PushService.instance.resolveTujuan({'url': 'https://siaran-contoh.test/c'}),
        const AksiBukaList(),
      );
      expect(
        PushService.instance.resolveTujuan({'notif_id': '9303'}),
        const AksiBukaList(),
        reason: 'ketukan privat setelah siaran tetap diproses',
      );
      expect(
        PushService.instance.resolveTujuan({'notif_id': '9303'}),
        isNull,
        reason: 'dedupe privat tetap aktif',
      );
    });

    test('payload kosong / tak dikenal → no-op (null)', () {
      expect(PushService.instance.resolveTujuan({}), isNull);
      expect(PushService.instance.resolveTujuan({'url': '   '}), isNull);
      expect(PushService.instance.resolveTujuan({'url': 'bukan-skema://x'}), isNull);
    });
  });

  group('PushService pending cold start & guard list', () {
    setUp(() {
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter();
    });

    tearDown(() {
      PushService.resetPendingUntukTest();
      DeepLinkService.instance.consumePendingId();
    });

    testWidgets('cold start: aksi bukaList menunggu dan dijalankan saat navigator siap',
        (tester) async {
      final key = NavigationService.instance.navigatorKey;

      // Ketukan datang sebelum UI siap: navigator masih null → diantrekan.
      PushService.instance.bukaListDariKetukan();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      await PushService.instance.terapkanPendingTerbuka();
      await tester.pumpAndSettle();

      expect(key.currentState!.canPop(), isTrue,
          reason: 'halaman daftar harus terdorong, bukan dibuka di atas login');
    });

    testWidgets('push list kedua dalam 2 detik dibatalkan (guard executor)',
        (tester) async {
      final key = NavigationService.instance.navigatorKey;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      PushService.instance.bukaListDariKetukan();
      await tester.pumpAndSettle();
      expect(key.currentState!.canPop(), isTrue);

      key.currentState!.pop();
      await tester.pumpAndSettle();

      PushService.instance.bukaListDariKetukan();
      await tester.pumpAndSettle();
      expect(key.currentState!.canPop(), isFalse,
          reason: 'kedatangan ganda satu ketukan tidak boleh membuka dua halaman');
    });
  });
}
