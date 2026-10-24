// Regresi JadwalUjianPage: tombol "Cetak Kartu" tidak lagi mengambang
// (FloatingActionButton) melainkan AppSection.trailing ala skripsi_page.
// Daftar kosong → tombol disabled; saat mengunduh → label "Mengunduh…".

import 'dart:convert';
import 'dart:typed_data';

import 'package:app_amikom/pages/jadwal_ujian_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Map<String, dynamic> _barisUjian({String mkl = 'Basis Data'}) => {
      'KODE': 'TIF123',
      'MKL': mkl,
      'TANGGAL': '08-07-2026',
      'HARI': 'Rabu',
      'RUANG': 'AULA',
      'JAM_MULAI': '08:00',
      'JAM_SELESEI': '09:40',
      'NOKURSI': 12,
    };

/// Adapter jadwal-ujian; [rows] null → fetch gagal (AppErrorState).
class _UjianAdapter implements HttpClientAdapter {
  _UjianAdapter(this.rows);

  List<Map<String, dynamic>>? rows;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = rows;
    if (!options.path.contains('/api/v1/akademik/jadwal-ujian') || data == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'status': 'success', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> pumpUjian(
  WidgetTester tester,
  List<Map<String, dynamic>>? rows,
) async {
  ApiClient.instance.dio.httpClientAdapter = _UjianAdapter(rows);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: const JadwalUjianPage()),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  testWidgets('tombol Cetak Kartu ada di trailing seksi, bukan FAB',
      (tester) async {
    await pumpUjian(tester, [_barisUjian()]);

    expect(tester.takeException(), isNull);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Cetak Kartu'), findsOneWidget);
    expect(find.text('1 mata kuliah'), findsOneWidget);

    // Tombol aktif saat daftar terisi.
    final tombol = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(tombol.onPressed, isNotNull);
  });

  testWidgets('daftar kosong → tombol disabled, tetap ada di trailing',
      (tester) async {
    await pumpUjian(tester, []);

    expect(tester.takeException(), isNull);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Belum Waktunya Ujian Nih!'), findsOneWidget);
    expect(find.text('0 mata kuliah'), findsOneWidget);

    final tombol = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(tombol.onPressed, isNull,
        reason: 'tanpa jadwal tidak ada kartu untuk dicetak');
  });

  testWidgets('galat memuat → AppErrorState + coba lagi', (tester) async {
    await pumpUjian(tester, null);

    expect(tester.takeException(), isNull);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
