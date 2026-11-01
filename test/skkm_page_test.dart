// Regresi SkkmPage: tiga keadaan utama — angkatan < 2024 (kebijakan, bukan
// galat), daftar terisi (statistik + baris + aksi bukti/hapus), dan kosong.
// Pola FakeAdapter seperti test/skkm_service_test.dart.

import 'dart:async';

import 'dart:convert';
import 'dart:typed_data';

import 'package:app_amikom/pages/skkm_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _SkkmPageAdapter implements HttpClientAdapter {
  _SkkmPageAdapter(this.payload);

  final Map<String, dynamic> payload;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!options.path.contains('/api/v1/skkm') || options.method != 'GET') {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'status': 'success', 'data': payload}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> pumpSkkm(WidgetTester tester, Map<String, dynamic> payload) async {
  ApiClient.instance.dio.httpClientAdapter = _SkkmPageAdapter(payload);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: const SkkmPage()),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Map<String, dynamic> get _payloadBerlaku => {
      'angkatan': 2025,
      'skkm_berlaku': true,
      'total_poin_valid': 55,
      'panduan_url': 'https://portal/Panduan_SKKM.pdf',
      'jumlah_aktivitas': 2,
      'opsi_unsur': [
        {'value': '2', 'label': 'Kegiatan Kepemimpinan'},
      ],
      'aktivitas': [
        {
          'no': 1,
          'kegiatan': {
            'unsur': 'Kegiatan Kepemimpinan',
            'sub_unsur': 'Panitia kegiatan',
            'level': 'Nasional',
            'jenis_keg': 'kelompok',
            'role': 'Sebagai ketua',
            'jml_anggota': 3,
          },
          'diupload_oleh': 'Mahasiswa',
          'kredit': 15,
          'status': 'Valid',
          'validator': 'PRODI',
          'bukti': {'id': '1791', 'url': 'https://portal/preview?id=1791'},
        },
        {
          'no': 2,
          'kegiatan': {
            'unsur': 'Kegiatan Kepemimpinan',
            'sub_unsur': 'Lomba organisasi',
            'level': 'Regional',
            'jenis_keg': 'individu',
          },
          'diupload_oleh': 'Mahasiswa',
          'kredit': 5,
          'status': 'Tidak Valid',
          'validator': 'KEMAHASISWAAN',
          'id_aktivitas': '1801',
          'komentar_validator': 'Bukti fisik tidak terbaca. Upload ulang.',
        },
      ],
    };

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  setUp(() {
    ApiClient.instance.dio.httpClientAdapter =
        _SkkmPageAdapter({'skkm_berlaku': false, 'aktivitas': []});
    // NIM angkatan 2025 (berlaku) — jalur normal tetap memanggil adapter.
    // setUserInfo menulis secure storage best-effort; di test environment
    // gagalnya ditelan, nilai in-memory yang terpakai.
    return ApiClient.instance.setUserInfo('25SA31A037', 'Tester');
  });

  testWidgets('angkatan < 2024 → penjelasan kebijakan, tanpa tombol tambah',
      (tester) async {
    await pumpSkkm(tester, {
      'angkatan': 2023,
      'skkm_berlaku': false,
      'total_poin_valid': null,
      'jumlah_aktivitas': 0,
      'aktivitas': [],
    });

    expect(tester.takeException(), isNull);
    expect(find.text('SKKM tidak berlaku untuk angkatanmu'), findsOneWidget);
    expect(find.text('angkatan 2024 ke atas'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('daftar terisi → statistik poin + baris + aksi unduh/hapus',
      (tester) async {
    await pumpSkkm(tester, _payloadBerlaku);

    expect(tester.takeException(), isNull);
    expect(find.text('55'), findsOneWidget, reason: 'poin valid');
    expect(find.text('Panitia kegiatan'), findsOneWidget);
    // "Valid" muncul 2x: label tile statistik + pil status baris pertama.
    expect(find.text('Valid'), findsNWidgets(2));
    expect(find.text('Tidak Valid'), findsOneWidget);
    expect(find.textContaining('Bukti fisik tidak terbaca'), findsOneWidget);
    expect(find.text('Unduh Bukti'), findsOneWidget,
        reason: 'hanya baris pertama yang punya bukti');
    expect(find.text('Hapus'), findsOneWidget,
        reason: 'hanya baris Tidak Valid yang bisa dihapus');
    // Tombol tambah + aksi sekunder.
    expect(find.text('Tambah Kegiatan'), findsOneWidget);
    expect(find.text('Kritik & Saran'), findsOneWidget);
  });

  testWidgets('angkatan berlaku tanpa aktivitas → kosong + tetap bisa tambah',
      (tester) async {
    await pumpSkkm(tester, {
      'angkatan': 2025,
      'skkm_berlaku': true,
      'total_poin_valid': 0,
      'panduan_url': '',
      'jumlah_aktivitas': 0,
      'aktivitas': [],
    });

    expect(tester.takeException(), isNull);
    expect(find.text('Belum ada kegiatan tercatat'), findsOneWidget);
    expect(find.text('Tambah Kegiatan'), findsOneWidget);
  });

  testWidgets('galat memuat → AppErrorState + coba lagi', (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _SkkmPageAdapter({
      'status': 'error',
    });
    // Adapter di atas hanya menjawab GET /skkm; buat fetch gagal total:
    ApiClient.instance.dio.httpClientAdapter =
        _AdapterSelaluGagal();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const SkkmPage()),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets(
      'NIM angkatan 2023 → kebijakan tampil TANPA menyentuh jaringan',
      timeout: const Timeout(Duration(seconds: 60)), (tester) async {
    // Adapter selalu gagal: bila halaman masih memanggil endpoint, halaman
    // akan menampilkan error — bukan penjelasan kebijakan.
    ApiClient.instance.dio.httpClientAdapter = _AdapterSelaluGagal();
    // TANPA await: setUserInfo menulis secure storage = I/O nyata yang tak
    // pernah selesai di zona FakeAsync testWidgets (di setUp luar zona itu
    // panggilan yang sama normal). NIM in-memory di-set sinkron di baris
    // pertama method — cukup untuk gerbang halaman.
    unawaited(ApiClient.instance.setUserInfo('2200001', 'Budi Santoso'));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const SkkmPage()),
    );
    // pump tetap, bukan pumpAndSettle — jalur tanpa jaringan tidak punya
    // frame berantai yang perlu dikejar.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('SKKM tidak berlaku untuk angkatanmu'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Coba lagi'), findsNothing,
        reason: 'tidak boleh ada panggilan jaringan sama sekali');
  });
}

class _AdapterSelaluGagal implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}
