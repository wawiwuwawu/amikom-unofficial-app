// Smoke test Fase 1b (render lazy): server mengirim daftar tanpa pagination,
// jadi halaman memecah daftar panjang (±300 item) menjadi chunk ±20 baris —
// satu AppListGroup per chunk — dirender via ListView.builder. Baris jauh
// belum dibangun sebelum discroll, dan scroll tetap bekerja.
// Pola mocking mengikuti jadwal_page_test.dart (FakeAdapter di atas dio).
//
// Catatan: dio punya BackgroundTransformer yang memecah JSON > 50 KB via
// isolate (compute) — isolate tidak pernah selesai di zona FakeAsync test.
// Karena payload daftar 300 item melampaui ambang itu, test memakai
// SyncTransformer agar decode tetap sinkron (konfigurasi test saja).

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/pages/keuangan_page.dart';
import 'package:app_amikom/pages/notifikasi_list_page.dart';
import 'package:app_amikom/pages/panduan_list_page.dart';
import 'package:app_amikom/pages/pengumuman_list_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';

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
    // Endpoint lain (mis. cek pembaruan, tagihan) dianggap mati di test.
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

List<Map<String, dynamic>> _notifikasiPayload(int n) => [
      for (var i = 0; i < n; i++)
        {
          'id': 'notif-$i',
          'judul': 'Notifikasi Uji $i',
          'tanggal': '24-10-2026',
        },
    ];

List<Map<String, dynamic>> _historyPayload(int n) => [
      for (var i = 0; i < n; i++)
        {
          'tahun_akademik': '2025/2026',
          'semester': (i % 2) + 1,
          'semester_tempuh': i + 1,
          'jumlah_bayar': 100000 * (i + 1),
          'tgl_bayar': '01-10-2026',
          'nomor_kwitansi': 'KW-$i',
          'angsuran_ke': i + 1,
          'channel_bank': 'BRIVA',
          'kode_bank': 1,
        },
    ];

List<Map<String, dynamic>> _pengumumanPayload(int n) => [
      for (var i = 0; i < n; i++)
        {
          'ID': i,
          'JUDUL': 'Pengumuman Uji $i',
          'TANGGAL': '24-10-2026',
        },
    ];

List<Map<String, dynamic>> _panduanPayload(int n) => [
      for (var i = 0; i < n; i++)
        {
          'ID': i,
          'JUDUL': 'Panduan Uji $i',
          'TANGGAL': '24-10-2026',
          'LINK': 'dokumen-$i',
        },
    ];

/// Scrollable milik RefreshIndicator halaman (bukan scrollable TabBarView).
Finder get _scrollList => find.descendant(
      of: find.byType(RefreshIndicator),
      matching: find.byType(Scrollable),
    );

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    SharedPreferences.setMockInitialValues({});
    // Payload daftar panjang > 50 KB akan dipar dio di background isolate
    // (compute) yang tak pernah selesai di zona FakeAsync test — pakai
    // transformer sinkron agar response langsung ter-decode.
    ApiClient.instance.dio.transformer = SyncTransformer();
  });

  testWidgets(
    'NotifikasiListPage: daftar 300 item dirender lazy dan tetap bisa discroll',
    (tester) async {
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter({
        '/api/v1/notifikasi/optin': (_) => _json({
              'status': 'success',
              'data': {'enabled': false, 'token_count': 0},
            }),
        '/api/v1/notifikasi': (_) => _json({
              'status': 'success',
              'data': _notifikasiPayload(300),
            }),
      });

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const NotifikasiListPage()),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      // Header & chunk pertama terlihat.
      expect(find.text('Notifikasi Uji 0'), findsOneWidget);
      expect(find.text('DAFTAR NOTIFIKASI'), findsOneWidget);
      // Baris jauh BELUM dibangun — bukti render lazy (dulu semua 300 item
      // dibangun sekaligus di children ListView).
      expect(find.text('Notifikasi Uji 150'), findsNothing);

      // Scroll bekerja: chunk berikutnya terbentuk saat dibutuhkan.
      await tester.scrollUntilVisible(
        find.text('Notifikasi Uji 40'),
        500,
        scrollable: _scrollList,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Notifikasi Uji 40'), findsOneWidget);
      expect(find.text('Notifikasi Uji 250'), findsNothing);
    },
  );

  testWidgets(
    'KeuanganPage: riwayat 300 item dirender lazy dan tetap bisa discroll',
    (tester) async {
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter({
        '/api/v1/keuangan/history': (_) => _json({
              'status': 'success',
              'total_bayar': 123456,
              'data': _historyPayload(300),
            }),
      });

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const KeuanganPage()),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      // Header ringkasan & chunk pertama terlihat.
      expect(find.text('Total Akumulasi Pembayaran'), findsOneWidget);
      expect(find.text('300 Kwitansi'), findsOneWidget);
      expect(find.text('Rp 100.000'), findsOneWidget);
      // Baris jauh BELUM dibangun — bukti render lazy.
      expect(find.text('Rp 25.100.000'), findsNothing);

      // Scroll bekerja: chunk berikutnya terbentuk saat dibutuhkan.
      await tester.scrollUntilVisible(
        find.text('Rp 4.100.000'), // item ke-40
        500,
        scrollable: _scrollList,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Rp 4.100.000'), findsOneWidget);
      expect(find.text('Rp 30.000.000'), findsNothing);
    },
  );

  testWidgets(
    'PengumumanListPage: daftar 300 item dirender lazy dan tetap bisa discroll',
    (tester) async {
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter({
        '/api/v1/pengumumanAkademik': (_) => _json({
              'status': 'success',
              'data': _pengumumanPayload(300),
            }),
      });

      await tester.pumpWidget(
        MaterialApp(
            theme: AppTheme.light(), home: const PengumumanListPage()),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      // Header & chunk pertama terlihat.
      expect(find.text('300 PENGUMUMAN'), findsOneWidget);
      expect(find.text('Pengumuman Uji 0'), findsOneWidget);
      // Baris jauh BELUM dibangun — bukti render lazy.
      expect(find.text('Pengumuman Uji 150'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Pengumuman Uji 40'),
        500,
        scrollable: _scrollList,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Pengumuman Uji 40'), findsOneWidget);
      expect(find.text('Pengumuman Uji 250'), findsNothing);
    },
  );

  testWidgets(
    'PanduanListPage: daftar 300 item dirender lazy dan tetap bisa discroll',
    (tester) async {
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter({
        '/api/v1/panduan': (_) => _json({
              'status': 'success',
              'data': _panduanPayload(300),
            }),
      });

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const PanduanListPage()),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      // Header seksi & chunk pertama terlihat.
      expect(find.text('DOKUMEN PANDUAN'), findsOneWidget);
      expect(find.text('Panduan Uji 0'), findsOneWidget);
      // Baris jauh BELUM dibangun — bukti render lazy.
      expect(find.text('Panduan Uji 150'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Panduan Uji 40'),
        500,
        scrollable: _scrollList,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Panduan Uji 40'), findsOneWidget);
      expect(find.text('Panduan Uji 250'), findsNothing);
    },
  );
}
