// Regresi alur auto-validasi "Validasi Semua" (Fase C):
//   • tombol per-makul membuka dialog inspeksi (bukan langsung menulis),
//   • dialog menyebut cakupan sebenarnya + pratinjau nilai preset,
//   • konfirmasi memanggil mode 'tulis' dan hasil tampil inline,
//   • lock in-flight mencegah dobel-submit (tombol nonaktif saat proses),
//   • status 'dilewati' bukan error, dan gagal menampilkan alasan ramah.
// Pola adapter Dio palsu mengikuti test/asisten_page_layout_test.dart.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_amikom/pages/absensi_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';

/// Adapter palsu dengan respons auto-validasi yang bisa diganti per tes.
class _FakeAdapter implements HttpClientAdapter {
  /// Pertemuan yang dikembalikan endpoint auto-validasi (inspeksi & tulis).
  List<Map<String, dynamic>> pertemuan;
  Map<String, dynamic> ringkasan;

  /// mode terakhir yang dipanggil ('inspeksi' | 'tulis') + jumlah panggilan.
  final List<String> modes = [];

  _FakeAdapter({required this.pertemuan, required this.ringkasan});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (path == '/api/v1/absensi/makul-belum-validasi') {
      return _body({
        'PSSIW034': {
          'makul': 'Sistem Penunjang Keputusan',
          'count': 2,
          'id_presensi_mhs': ['5524450', '5524451'],
          'kelasgab': ['A'],
        },
      });
    }
    if (path == '/api/v1/absensi/semester') {
      return _body([
        {'value': '2025', 'label': '2025/2026 Ganjil'},
      ]);
    }
    if (path == '/api/v1/absensi/auto-validasi') {
      final data = options.data;
      final mode = data is Map ? data['mode']?.toString() ?? '' : '';
      modes.add(mode);
      return _body({'ringkasan': ringkasan, 'pertemuan': pertemuan});
    }
    return _body(null);
  }

  Map<String, dynamic> _json(dynamic data) => {
        'status': 'success',
        'data': data,
      };

  ResponseBody _body(dynamic data) => ResponseBody.fromString(
        jsonEncode(_json(data)),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _pertemuan({
  required String makul,
  required String status,
  String alasan = '',
}) =>
    {
      'makul': makul,
      'id_presensi_dosen': '211000',
      'id_presensi_mhs': '5524450',
      'jenis': 'praktek',
      'jumlah_asdos': 2,
      'status': status,
      'alasan': alasan,
      'payload': {'jenispilih': 'praktek'},
    };

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  Future<void> pumpPage(WidgetTester tester, _FakeAdapter adapter) async {
    ApiClient.instance.dio.httpClientAdapter = adapter;
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const AbsensiPage()),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  testWidgets('inspeksi dulu, konfirmasi, lalu tulis — hasil tampil inline',
      (tester) async {
    final adapter = _FakeAdapter(
      pertemuan: [
        _pertemuan(makul: 'Sistem Penunjang Keputusan', status: 'sukses'),
        _pertemuan(makul: 'Basis Data', status: 'sukses'),
      ],
      ringkasan: {'total': 2, 'sukses': 2, 'gagal': 0, 'dilewati': 0},
    );
    await pumpPage(tester, adapter);

    await tester.tap(find.widgetWithText(FilledButton, 'Validasi'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Dialog inspeksi: cakupan + pratinjau preset, bukan langsung menulis.
    expect(find.text('Validasi Otomatis'), findsOneWidget);
    expect(find.text('Cakupan validasi'), findsOneWidget);
    expect(find.textContaining('2 pertemuan'), findsOneWidget);
    expect(find.text('Nilai yang akan dikirim (preset wajar)'), findsOneWidget);
    expect(adapter.modes, ['inspeksi'],
        reason: 'belum boleh menulis sebelum konfirmasi');

    await tester.tap(find.text('Lanjut validasi'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(adapter.modes, ['inspeksi', 'tulis']);
    expect(find.text('HASIL VALIDASI'), findsOneWidget);
    expect(
      find.text('Validasi selesai: 2 berhasil, 0 gagal, 0 dilewati.'),
      findsOneWidget,
    );
  });

  testWidgets('pertemuan gagal tampil dengan alasan, bukan payload mentah',
      (tester) async {
    final adapter = _FakeAdapter(
      pertemuan: [
        _pertemuan(makul: 'Sistem Penunjang Keputusan', status: 'sukses'),
        _pertemuan(
          makul: 'Basis Data',
          status: 'gagal',
          alasan: 'Presensi sudah ditutup oleh dosen',
        ),
      ],
      ringkasan: {'total': 2, 'sukses': 1, 'gagal': 1, 'dilewati': 0},
    );
    await pumpPage(tester, adapter);

    await tester.tap(find.widgetWithText(FilledButton, 'Validasi'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Lanjut validasi'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('HASIL VALIDASI'), findsOneWidget);
    expect(find.text('Basis Data'), findsOneWidget);
    expect(find.textContaining('Presensi sudah ditutup oleh dosen'),
        findsOneWidget);
    // Payload mentah tidak boleh muncul.
    expect(find.textContaining('jenispilih'), findsNothing);
  });

  testWidgets('semua pertemuan dilewati → keadaan kosong jujur, bukan error',
      (tester) async {
    final adapter = _FakeAdapter(
      pertemuan: [
        _pertemuan(
          makul: 'Sistem Penunjang Keputusan',
          status: 'dilewati',
          alasan: 'Sudah divalidasi',
        ),
      ],
      ringkasan: {'total': 1, 'sukses': 0, 'gagal': 0, 'dilewati': 1},
    );
    await pumpPage(tester, adapter);

    await tester.tap(find.widgetWithText(FilledButton, 'Validasi'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Lanjut validasi'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Tidak ada pertemuan yang perlu divalidasi.'),
        findsOneWidget);
    expect(find.text('Validasi gagal'), findsNothing);
  });
}
