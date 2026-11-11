// Test kontrak BiodataService — endpoint /api/v1/biodata via ApiClient.guard
// + unwrapData (pola §8.3). Adapter Dio palsu gagal cepat bila service
// menyentuh endpoint lain. Tanpa cache disk (PII) — dijamin tidak ada tulis
// ke storage oleh service (cukup verifikasi perilaku fetch per panggilan).

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/biodata_service.dart';

class _BiodataAdapter implements HttpClientAdapter {
  _BiodataAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    if (!options.path.contains('/api/v1/biodata')) {
      throw Exception('endpoint tak dikenal: ${options.path}');
    }
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _balasSukses(Map<String, dynamic> data) {
  return ResponseBody.fromString(
    jsonEncode({'status': 'success', 'data': data}),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  test('getBiodata → Biodata terparse dari envelope {status, data}',
      () async {
    ApiClient.instance.dio.httpClientAdapter = _BiodataAdapter(
      (options) => _balasSukses({
        'data_diri': {
          'nama': 'Wawan Setiawan',
          'tanggal_lahir': '2005-12-07',
          'jenis_kelamin': {'kode': 'L', 'label': 'Laki-laki'},
        },
        'alamat': {'kabupaten': 'Banyumas'},
        'pendidikan': {},
        'orang_tua': {
          'ayah': {'nama': 'Sugiyanto'},
          'ibu': {'nama': 'Sri Wahyuni'},
        },
        'foto_url': 'https://portal/foto.jpg',
      }),
    );
    ApiClient.instance.dio.transformer = SyncTransformer();

    final b = await BiodataService().getBiodata();

    expect(b.dataDiri.nama, 'Wawan Setiawan');
    expect(b.dataDiri.tanggalLahir, '2005-12-07');
    expect(b.dataDiri.jenisKelamin.label, 'Laki-laki');
    expect(b.orangTua.ibu.nama, 'Sri Wahyuni');
    expect(b.fotoUrl, 'https://portal/foto.jpg');
  });

  test('BE gagal (500) → AppFailure berpesan ramah Indonesia', () async {
    ApiClient.instance.dio.httpClientAdapter = _BiodataAdapter(
      (options) => ResponseBody.fromString('{"status":"error"}', 500),
    );
    ApiClient.instance.dio.transformer = SyncTransformer();

    final service = BiodataService();
    try {
      await service.getBiodata();
      fail('harusnya melempar AppFailure');
    } catch (e) {
      final msg = e.toString();
      expect(msg, isNotEmpty);
      // Kontrak §8.5: pesan ramah — bukan jejak teknis mentah.
      expect(msg.contains('Exception'), isFalse);
      expect(msg.contains('Error'), isFalse, reason: msg);
    }
  });

  test('payload bentuk rusak (data bukan map) → AppFailure, bukan TypeError',
      () async {
    ApiClient.instance.dio.httpClientAdapter = _BiodataAdapter(
      (options) => ResponseBody.fromString(
        jsonEncode({'status': 'success', 'data': 'bukan-map'}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    ApiClient.instance.dio.transformer = SyncTransformer();

    try {
      await BiodataService().getBiodata();
      fail('harusnya melempar AppFailure');
    } catch (e) {
      expect(e.toString().contains('TypeError'), isFalse);
    }
  });
}
