// Widget test KhsPage — adopsi arahan BE 2026-11-11 (Rincian Nilai) diterapkan
// konsisten: auto-select tahun terakhir + semester pertama setelah opsi
// termuat, lalu detail PERTAMA dimuat otomatis (tanpa menekan tombol cari).
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

import 'package:app_amikom/pages/khs_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/widgets/app_kit.dart';

class _KhsAdapter implements HttpClientAdapter {
  _KhsAdapter(this.handlers);

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

ResponseBody _detailKhs() => _ok({
      'data': [
        {'KODE': 'TIF123', 'MKL': 'Pemrograman Mobile', 'SKS': 3,
         'AMBILKE': '1', 'NILAI': 'A', 'BOBOT': 4.0},
      ],
      'finish_evaluasi': true,
      'can_view_skripsi': false,
    });

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> pompa(WidgetTester tester, _KhsAdapter adapter) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.dio.httpClientAdapter = adapter;
    ApiClient.instance.dio.transformer = SyncTransformer();
    unawaited(ApiClient.instance.setUserInfo('2212400011', 'Tester'));
    addTearDown(() => ApiClient.instance.clearTokens());
    await tester.pumpWidget(const MaterialApp(home: KhsPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('opsi termuat → tahun terakhir + semester pertama auto-selected, detail langsung dimuat',
      (tester) async {
    final adapter = _KhsAdapter({
      '/api/v1/khs': (options) {
        if (options.path.contains('/khs/detail')) return _detailKhs();
        return _ok({
          'tahun_akademik': [
            {'value': '2026/2027', 'label': '2026/2027'},
            {'value': '2025/2026', 'label': '2025/2026'},
          ],
          'semester': [
            {'value': '1', 'label': 'Semester Ganjil'},
            {'value': '2', 'label': 'Semester Genap'},
          ],
        });
      },
    });
    await pompa(tester, adapter);

    // Auto-select: Ganjil tampil di trigger (bukan hint), tanpa menekan apa pun.
    expect(find.text('Semester Ganjil').hitTestable(), findsOneWidget);
    expect(find.text('2026/2027').hitTestable(), findsOneWidget);

    // Detail PERTAMA dimuat otomatis: POST /khs/detail dengan thn+smt
    // auto-selected — tanpa tombol cari.
    final detailReqs = adapter.requests
        .where((r) => r.path.contains('/khs/detail'))
        .toList();
    expect(detailReqs.length, 1);
    expect(detailReqs.single.data['thn'], '2026/2027');
    expect(detailReqs.single.data['smt'], '1');

    // Isi detail tampil.
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
  });

  testWidgets('BE gagal → AppErrorState ramah + tombol coba lagi, tanpa detail teknis',
      (tester) async {
    final adapter = _KhsAdapter({
      '/api/v1/khs': (options) => ResponseBody.fromString(
            jsonEncode({'status': 'error', 'message': 'boom'}),
            500,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          ),
    });
    await pompa(tester, adapter);

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'DioException|Exception|boom|500')),
      findsNothing,
    );
  });
}
