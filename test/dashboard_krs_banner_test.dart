// Regresi banner "Periode KRS Dibuka" di Beranda (kontrak BE §2.3
// `GET /api/v1/periode?scope=krs`): tampil hanya selama periode dibuka,
// bisa ditutup manual (tombol X) dan penutupan berlaku PER-PERIODE — periode
// baru (rentang tanggal berbeda) otomatis menampilkan banner lagi.
// Endpoint gagal → fail-open: tanpa banner, tanpa galat UI.
// Pola FakeAdapter seperti test/dashboard_sp_banner_test.dart.

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

const _kunciKrsDitutup = 'krs_banner_ditutup_periode';

class _KrsBannerAdapter implements HttpClientAdapter {
  _KrsBannerAdapter({this.periodeGagal = false, this.krsDibuka = true});

  /// true → /periode melempar connectionError (simulasi BE lama).
  final bool periodeGagal;

  /// Nilai `data.krs.dibuka` yang dijawab endpoint periode.
  final bool krsDibuka;

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
        'has_rekomendasi': false,
        'warning_message': '',
        'total_rekomendasi': 0,
        'total_sks': 0,
        'kategori_sangat_dianjurkan': [],
        'kategori_opsional_sks_besar': [],
      });
    }
    if (options.path.contains('/api/v1/periode')) {
      if (periodeGagal) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return json({
        'krs': {
          'dibuka': krsDibuka,
          'mulai': '2026-11-02',
          'selesai': '2026-11-07',
          'pengajuan': {'dibuka': krsDibuka, 'mulai': null, 'selesai': null},
          'pengisian': {'dibuka': krsDibuka, 'mulai': null, 'selesai': null},
        },
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

Future<void> pumpDashboard(
  WidgetTester tester, {
  bool periodeGagal = false,
  bool krsDibuka = true,
}) async {
  ApiClient.instance.dio.httpClientAdapter = _KrsBannerAdapter(
    periodeGagal: periodeGagal,
    krsDibuka: krsDibuka,
  );
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

  testWidgets('periode KRS dibuka → banner tampil dengan rentang tanggal', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Periode KRS Dibuka'), findsOneWidget);
    expect(find.text('Berlaku sampai 2 November 2026 – 7 November 2026'),
        findsOneWidget);
    expect(find.text('Isi KRS'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
  });

  testWidgets('tutup manual → banner hilang + kunci periode tersimpan', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pumpAndSettle();

    expect(find.text('Periode KRS Dibuka'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_kunciKrsDitutup), '2026-11-02..2026-11-07');
  });

  testWidgets('periode sama dibuka ulang → tetap tersembunyi', (tester) async {
    SharedPreferences.setMockInitialValues({
      _kunciKrsDitutup: '2026-11-02..2026-11-07',
    });
    await pumpDashboard(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Periode KRS Dibuka'), findsNothing);
  });

  testWidgets('periode BARU (tanggal beda) → banner muncul lagi', (tester) async {
    SharedPreferences.setMockInitialValues({
      _kunciKrsDitutup: '2026-05-04..2026-05-09',
    });
    await pumpDashboard(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Periode KRS Dibuka'), findsOneWidget,
        reason: 'penutupan per-periode: periode baru menampilkan banner lagi');
  });

  testWidgets('periode tidak dibuka → tanpa banner', (tester) async {
    await pumpDashboard(tester, krsDibuka: false);

    expect(tester.takeException(), isNull);
    expect(find.text('Periode KRS Dibuka'), findsNothing);
  });

  testWidgets('endpoint periode gagal → fail-open tanpa banner tanpa galat', (
    tester,
  ) async {
    await pumpDashboard(tester, periodeGagal: true);

    expect(tester.takeException(), isNull);
    expect(find.text('Periode KRS Dibuka'), findsNothing);
  });
}
