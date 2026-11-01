// Regresi banner rekomendasi Semester Pendek di Beranda: bisa ditutup manual
// (tombol X), tetap tersembunyi SELAMA isi rekomendasi tidak berubah, dan
// muncul kembali begitu isi berubah (nilai baru masuk). Patokan ISI, bukan
// timer bulanan — menagging tiap bulan terasa seperti spam (masukan user
// 2026-11-01).
// Pola FakeAdapter seperti test/dashboard_presensi_tercatat_test.dart.

import 'dart:convert';
import 'dart:typed_data';

import 'package:app_amikom/pages/dashboard_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/utils/waktu.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kunciSpDitutupIsi = 'sp_rekomendasi_ditutup_isi';

/// Tanda tangan isi yang dihitung DashboardPage: "kode:SKS" terurut digabung
/// '|'. Harus konsisten dengan _spIsiSignature di dashboard_page.dart.
String _signature(List<Map<String, Object>> dianjurkan,
    [List<Map<String, Object>> opsional = const []]) {
  final baris = [
    for (final e in [...dianjurkan, ...opsional]) '${e['kode']}:${e['sks']}',
  ]..sort();
  return baris.join('|');
}

const _mkDianjurkan = [
  {
    'kode': 'TIF3204',
    'mkl': 'Kecerdasan Buatan',
    'sks': 3,
    'nilai_sebelumnya': 'C-',
    'alasan': 'Nilai di bawah standar kelulusan',
  },
];

const _mkOpsional = [
  {
    'kode': 'TIF2201',
    'mkl': 'Sistem Digital',
    'sks': 2,
    'nilai_sebelumnya': 'C',
    'alasan': 'Beban SKS besar',
  },
];

class _SpBannerAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Future<ResponseBody> json(Object data) async => ResponseBody.fromString(
      jsonEncode({'status': 'success', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

    if (options.path.contains('/api/v1/dashboard')) {
      return json({
        'profile': {
          'npm': '2200001',
          'nama': 'Budi Santoso',
          'prodi': 'Informatika',
          'angkatan': 2022,
          'fakultas': 'FILKOM',
          'email': 'budi@example.com',
          'no_hp': '',
          'pembimbing_akademik': 'Dosen PA',
          'foto_url': '',
        },
        'statistik': {'total_sks': 100, 'ipk': 3.5},
        'status': {'status': 'Aktif'},
      });
    }
    if (options.path.contains('/api/v1/agenda/terpadu')) {
      return json({
        'total_agenda': 0,
        'agenda': {namaHariDariWeekday(DateTime.now().weekday): []},
      });
    }
    if (options.path.contains('/api/v1/sp/rekomendasi')) {
      return json({
        'has_rekomendasi': true,
        'warning_message': 'Kamu disarankan mengambil SP.',
        'total_rekomendasi': 2,
        'total_sks': 5,
        'kategori_sangat_dianjurkan': _mkDianjurkan,
        'kategori_opsional_sks_besar': _mkOpsional,
      });
    }

    // Endpoint lain (skripsi, absensi, notifikasi, pembaruan) dianggap
    // mati di test — dashboard fail-open (banner terkait tidak tampil).
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> pumpDashboard(WidgetTester tester) async {
  ApiClient.instance.dio.httpClientAdapter = _SpBannerAdapter();
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: const DashboardPage()),
  );
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('pertama install → banner tampil dengan tombol tutup', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Rekomendasi Semester Pendek'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
  });

  testWidgets('tutup manual → banner hilang + ISI rekomendasi tersimpan di prefs',
      (tester) async {
    await pumpDashboard(tester);

    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pumpAndSettle();

    expect(find.text('Rekomendasi Semester Pendek'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_kunciSpDitutupIsi),
        _signature(_mkDianjurkan, _mkOpsional));
  });

  testWidgets('isi rekomendasi sama → tetap tersembunyi saat app dibuka ulang',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      _kunciSpDitutupIsi: _signature(_mkDianjurkan, _mkOpsional),
    });
    await pumpDashboard(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Rekomendasi Semester Pendek'), findsNothing);
  });

  testWidgets('isi rekomendasi berubah (nilai baru masuk) → banner muncul lagi',
      (tester) async {
    // Daftar lama yang pernah ditutup — kini ada MK baru di rekomendasi.
    SharedPreferences.setMockInitialValues({
      _kunciSpDitutupIsi: _signature(_mkDianjurkan),
    });
    await pumpDashboard(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Rekomendasi Semester Pendek'), findsOneWidget);
  });
}
