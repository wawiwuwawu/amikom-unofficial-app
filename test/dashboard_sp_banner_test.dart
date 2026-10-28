// Regresi banner rekomendasi Semester Pendek di Beranda: bisa ditutup manual
// (tombol X), tetap tersembunyi setelah app dibuka ulang selama 30 hari, lalu
// muncul kembali setelah rentang itu. Event SP hanya sesekali (antara UAS dan
// semester baru) — jangan menagging tiap buka app.
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

const _kunciSpDitutupAt = 'sp_rekomendasi_ditutup_at';

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
        'total_sks': 6,
        'kategori_sangat_dianjurkan': [],
        'kategori_opsional_sks_besar': [],
      });
    }

    // Endpoint lain (absensi, notifikasi, pembaruan) dianggap mati di test.
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

Future<void> setDitutupPada(DateTime waktu) async {
  SharedPreferences.setMockInitialValues({
    _kunciSpDitutupAt: waktu.millisecondsSinceEpoch,
  });
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

  testWidgets('tutup manual → banner hilang + waktu tersimpan di prefs', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pumpAndSettle();

    expect(find.text('Rekomendasi Semester Pendek'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    final ditutupAt = prefs.getInt(_kunciSpDitutupAt);
    expect(ditutupAt, isNotNull);
    expect(
      DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(ditutupAt!))
          .inSeconds,
      lessThan(60),
    );
  });

  testWidgets('sudah ditutup < 30 hari → tetap tersembunyi saat app dibuka ulang',
      (tester) async {
    await setDitutupPada(DateTime.now().subtract(const Duration(days: 5)));
    await pumpDashboard(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Rekomendasi Semester Pendek'), findsNothing);
  });

  testWidgets('sudah lewat 30 hari → banner muncul lagi', (tester) async {
    await setDitutupPada(DateTime.now().subtract(const Duration(days: 31)));
    await pumpDashboard(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Rekomendasi Semester Pendek'), findsOneWidget);
  });
}
