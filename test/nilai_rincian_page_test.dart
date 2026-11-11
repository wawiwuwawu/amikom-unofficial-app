// Widget test NilaiRincianPage — adopsi arahan BE 2026-11-11: daftar semester
// adalah cermin persis portal per-tahun. FE fetch semester SELALU membawa
// thn_akademik (alur per-tahun), auto-select tanpa placeholder, dan JANGAN
// mensintesis 'Genap'. Kontrak final BE: single-entry 2026/2027 itu benar.
//
// Pola: adapter Dio palsu + dotenv.loadFromString setUpAll + SyncTransformer
// + mock secure storage/prefs bawaan plugin.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/pages/nilai_rincian_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/widgets/app_kit.dart';

/// Adapter yang mencatat setiap request GET: path + query — dipakai untuk
/// memverifikasi bahwa semester selalu di-fetch dengan thn_akademik.
class _NilaiAdapter implements HttpClientAdapter {
  _NilaiAdapter(this.handlers);

  /// matcher path → balasan. Dipanggil matcher pertama yang `hasMatch`.
  final Map<String, ResponseBody Function(RequestOptions options)> handlers;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    for (final entry in handlers.entries) {
      if (options.path.contains(entry.key)) return entry.value(options);
    }
    throw Exception('endpoint tak dikenal: ${options.path}');
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _ok(Object data) => ResponseBody.fromString(
      jsonEncode({'status': 'success', 'data': data}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );

/// Envelope rincian nilai minimal (root-level fields — unwrapRoot).
ResponseBody _rincian(String thn, String smtId) => ResponseBody.fromString(
      jsonEncode({
        'status': 'success',
        'thn_akademik': thn,
        'semester_id': smtId,
        'semester_label': 'Semester $smtId',
        'thn_aktif': thn,
        'data': [],
        'rentang_nilai': [],
      }),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> pompa(
    WidgetTester tester,
    _NilaiAdapter adapter,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.dio.httpClientAdapter = adapter;
    ApiClient.instance.dio.transformer = SyncTransformer();
    unawaited(ApiClient.instance.setUserInfo('2212400011', 'Tester'));
    addTearDown(() => ApiClient.instance.clearTokens());
    await tester.pumpWidget(const MaterialApp(home: NilaiRincianPage()));
    await tester.pumpAndSettle();
  }

  List<RequestOptions> semRequests(_NilaiAdapter adapter) => adapter.requests
      .where((r) => r.path.contains('/nilai/semester'))
      .toList();

  testWidgets('initial load: semester di-fetch DENGAN thn_akademik (alur per-tahun)',
      (tester) async {
    final adapter = _NilaiAdapter({
      '/nilai/tahun-akademik': (_) => _ok(const [
            {'value': '2026/2027', 'label': '2026/2027'},
            {'value': '2025/2026', 'label': '2025/2026'},
          ]),
      '/nilai/semester': (options) => _ok(const [
            {'value': '1', 'label': 'Semester Ganjil'},
          ]),
      '/nilai/rincian': (_) => _rincian('2026/2027', '1'),
    });
    await pompa(tester, adapter);

    // Hanya satu request semester, dan membawa thn_akademik tahun terakhir.
    final semReqs = semRequests(adapter);
    expect(semReqs.length, 1);
    expect(semReqs.single.queryParameters['thn_akademik'], '2026/2027');

    // Auto-select: Ganjil terpilih (bukan hint), walau opsi tunggal.
    expect(find.text('Semester Ganjil').hitTestable(), findsOneWidget);
  });

  testWidgets(
      'tahun berjalan hanya punya Ganjil → tampil apa adanya, TANPA Genap sintesis',
      (tester) async {
    final adapter = _NilaiAdapter({
      '/nilai/tahun-akademik': (_) => _ok(const [
            {'value': '2026/2027', 'label': '2026/2027'},
          ]),
      '/nilai/semester': (_) => _ok(const [
            {'value': '1', 'label': 'Semester Ganjil'},
          ]),
      '/nilai/rincian': (_) => _rincian('2026/2027', '1'),
    });
    await pompa(tester, adapter);

    // Ganjil tampil; 'Genap' tidak boleh disintesis FE (arahan #1 BE).
    expect(find.text('Semester Ganjil').hitTestable(), findsOneWidget);
    expect(find.text('Semester Genap'), findsNothing);
  });

  testWidgets('ganti tahun → semester di-fetch ulang membawa tahun baru + rincian langsung dimuat',
      (tester) async {
    final adapter = _NilaiAdapter({
      '/nilai/tahun-akademik': (_) => _ok(const [
            {'value': '2026/2027', 'label': '2026/2027'},
            {'value': '2025/2026', 'label': '2025/2026'},
          ]),
      '/nilai/semester': (options) {
        final thn = options.queryParameters['thn_akademik'];
        // 2026/2027 (berjalan) hanya Ganjil; 2025/2026 Ganjil+Genap.
        if (thn == '2026/2027') {
          return _ok(const [
            {'value': '1', 'label': 'Semester Ganjil'},
          ]);
        }
        return _ok(const [
          {'value': '1', 'label': 'Semester Ganjil'},
          {'value': '2', 'label': 'Semester Genap'},
        ]);
      },
      '/nilai/rincian': (_) => _rincian('2026/2027', '1'),
    });
    await pompa(tester, adapter);

    // Buka dropdown tahun & pilih 2025/2026.
    await tester.tap(find.text('2026/2027').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2025/2026').last);
    await tester.pumpAndSettle();

    // Dua request semester: initial (2026/2027) + ganti tahun (2025/2026).
    final semReqs = semRequests(adapter);
    expect(semReqs.length, 2);
    expect(semReqs.last.queryParameters['thn_akademik'], '2025/2026');

    // Semester pertama (Ganjil) auto-selected → rincian langsung dimuat.
    expect(find.text('Semester Ganjil').hitTestable(), findsOneWidget);

    // Buka dropdown semester: kedua opsi tampil apa adanya (Ganjil + Genap).
    await tester.tap(find.text('Semester Ganjil').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Semester Genap'), findsOneWidget);
    // Tutup menu (pilih kembali Ganjil — tidak memicu fetch tahun).
    await tester.tap(find.text('Semester Ganjil').last);
    await tester.pumpAndSettle();
  });

  testWidgets('ganti tahun gagal → AppErrorState ramah + tanpa jejak teknis',
      (tester) async {
    final adapter = _NilaiAdapter({
      '/nilai/tahun-akademik': (_) => _ok(const [
            {'value': '2026/2027', 'label': '2026/2027'},
            {'value': '2025/2026', 'label': '2025/2026'},
          ]),
      '/nilai/semester': (options) {
        final thn = options.queryParameters['thn_akademik'];
        if (thn == '2025/2026') {
          return ResponseBody.fromString(
            jsonEncode({'status': 'error', 'message': 'boom'}),
            500,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return _ok(const [
          {'value': '1', 'label': 'Semester Ganjil'},
        ]);
      },
      '/nilai/rincian': (_) => _rincian('2026/2027', '1'),
    });
    await pompa(tester, adapter);

    await tester.tap(find.text('2026/2027').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2025/2026').last);
    await tester.pumpAndSettle();

    // Galat ditampilkan jujur (bukan disamarkan jadi kosong), tanpa detail
    // teknis (kontrak pesan galat §8.5).
    expect(find.byType(AppErrorState), findsOneWidget);
    final pageText = find.byType(NilaiRincianPage);
    expect(
      find.descendant(
        of: pageText,
        matching: find.textContaining(RegExp(r'DioException|Exception|boom|500')),
      ),
      findsNothing,
    );
  });

  testWidgets('rincian awal kosong → fetch rincian spesifik dengan thn+smt terpilih',
      (tester) async {
    final adapter = _NilaiAdapter({
      '/nilai/tahun-akademik': (_) => _ok(const [
            {'value': '2026/2027', 'label': '2026/2027'},
          ]),
      '/nilai/semester': (_) => _ok(const [
            {'value': '1', 'label': 'Semester Ganjil'},
          ]),
      '/nilai/rincian': (options) {
        // Tanpa param (initial) → kembalikan envelope tanpa data, sehingga
        // halaman memicu _fetchRincian dengan thn+smt terpilih.
        if (options.queryParameters.isEmpty) return _rincian('', '');
        return _rincian('2026/2027', '1');
      },
    });
    await pompa(tester, adapter);

    final rincianReqs = adapter.requests
        .where((r) => r.path.contains('/nilai/rincian'))
        .toList();
    // Initial (tanpa param) + fetch spesifik (thn+smt terpilih).
    expect(rincianReqs.length, 2);
    expect(rincianReqs.last.queryParameters['thn_akademik'], '2026/2027');
    expect(rincianReqs.last.queryParameters['semester'], '1');
  });
}

