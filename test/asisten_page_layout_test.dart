// Regresi layout: baris kartu ringkasan (`AppStatTile`) tidak boleh memakai
// `CrossAxisAlignment.stretch` di dalam scrollable yang tingginya tak terbatas.
// Stretch memaksa tinggi `infinity` ke anak dan Flutter melempar:
//   BoxConstraints forces an infinite height.
//   ... Row Row:file:///.../asisten_page.dart
// Pola ini muncul di beberapa halaman (asisten, khs, sp, krs) akibat migrasi
// design system; berkas ini menjaga halaman Asisten Praktikum.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_amikom/pages/asisten_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';

/// Adapter Dio palsu: membalas payload minimal yang sah untuk halaman Asisten.
class _FakeAdapter implements HttpClientAdapter {
  static const Map<String, Map<String, dynamic>> _responses = {
    '/api/v1/asisten/info': {
      'status': 'success',
      'data': {
        'mahasiswa': {
          'npm': '23SA21A060',
          'NAMA': 'DEDE',
          'nama_dept': 'SISTEM INFORMASI',
        },
        'stats': {
          'hadir': 10,
          'izin': 1,
          'pengganti': 2,
          'alpa': 0,
          'rataRataMhs': 12,
        },
        'aturan': <String, dynamic>{},
        'bisaAjukanBebasKP': false,
      },
    },
    '/api/v1/asisten/tahun-akademik': {
      'status': 'success',
      'data': [
        {'ID_TAHUN': 1, 'THN_AKADEMIK': '2025/2026', 'SEMESTER': 1},
      ],
    },
    '/api/v1/asisten/laporan': {
      'status': 'success',
      'data': {'labels': <String>[], 'datasets': <dynamic>[]},
    },
    '/api/v1/asisten/jadwal': {'status': 'success', 'data': <dynamic>[]},
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body =
        _responses[options.path] ?? {'status': 'success', 'data': null};
    return ResponseBody.fromString(
      jsonEncode(body),
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
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  testWidgets('baris ringkasan asisten tidak memaksa tinggi tak terbatas',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter();

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const AsistenPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Dulu gagal di sini: "BoxConstraints forces an infinite height".
    expect(tester.takeException(), isNull);

    // Baris kartu ringkasan harus benar-benar ter-render, bukan kolaps.
    // `AppSection` menampilkan judul dalam huruf kapital.
    expect(find.text('RINGKASAN KEHADIRAN'), findsOneWidget);
    for (final label in ['Hadir', 'Izin', 'Ganti', 'Alpa']) {
      expect(find.text(label), findsOneWidget, reason: 'Kartu $label hilang.');
    }
    expect(tester.getSize(find.text('Hadir')).height, greaterThan(10));
  });
}
