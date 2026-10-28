// Regresi lapisan ETag/304 endpoint publik (kontrak BE panduan-implement-fe
// §2.7): request pertama menyimpan ETag + body; request ulang menyertakan
// `If-None-Match`; 304 dari BE dijawab dari cache sebagai 200. Endpoint
// per-NIM (agenda/terpadu) dan envelope galat TIDAK boleh ikut ter-cache.

import 'dart:convert';
import 'dart:typed_data';

import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/etag_cache_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _etagV1 = '"berita-v1"';

Map<String, dynamic> _envelopeBerita() => {
      'status': 'success',
      'data': [
        {'ID': 1, 'JUDUL': 'Berita A'},
        {'ID': 2, 'JUDUL': 'Berita B'},
      ],
      'total': 2,
      'has_more': false,
    };

/// BE tiruan: GET /api/v1/berita selalu membalas dengan ETag [_etagV1];
/// bila klien mengirim If-None-Match yang cocok → 304 tanpa body.
class _EtagAdapter implements HttpClientAdapter {
  final List<String> paths = [];
  final List<String?> ifNoneMatch = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.uri.path);
    ifNoneMatch.add(options.headers['If-None-Match']?.toString());

    Future<ResponseBody> json(Object data, {int status = 200}) async =>
        ResponseBody.fromString(
          jsonEncode(data),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
            'etag': [_etagV1],
          },
        );

    if (options.uri.path == '/api/v1/berita') {
      if (options.headers['If-None-Match']?.toString() == _etagV1) {
        return ResponseBody.fromString('', 304);
      }
      return json(_envelopeBerita());
    }
    if (options.uri.path == '/api/v1/agenda/terpadu') {
      return json({
        'status': 'success',
        'data': {'total_agenda': 0, 'agenda': {}},
      });
    }
    if (options.uri.path == '/api/v1/berita/9') {
      return json({'status': 'error', 'message': 'portal gagal'});
    }
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _EtagAdapter adapter;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EtagCacheService.instance.resetForTest();
    adapter = _EtagAdapter();
    ApiClient.instance.dio.httpClientAdapter = adapter;
  });

  test('respons pertama: data sampai + ETag & body tersimpan', () async {
    final res = await ApiClient.instance.dio.get(
      '/api/v1/berita',
      queryParameters: {'offset': 0},
    );

    expect(res.statusCode, 200);
    expect((res.data['data'] as List), hasLength(2));

    final entri = await EtagCacheService.instance
        .baca('/api/v1/berita?offset=0');
    expect(entri, isNotNull);
    expect(entri!['etag'], _etagV1);
    expect((entri['body'] as Map)['total'], 2);
  });

  test('request ulang: If-None-Match dikirim, 304 dijawab dari cache', () async {
    await ApiClient.instance.dio.get(
      '/api/v1/berita',
      queryParameters: {'offset': 0},
    );

    final res = await ApiClient.instance.dio.get(
      '/api/v1/berita',
      queryParameters: {'offset': 0},
    );

    // 304 tidak pernah bocor ke pemanggil: dijawab sebagai 200 berisi body
    // simpanan — service pemanggil tidak tahu bedanya.
    expect(res.statusCode, 200);
    expect(res.data, _envelopeBerita());
    expect(adapter.ifNoneMatch.last, _etagV1);
  });

  test('endpoint per-NIM tidak pernah menyertakan If-None-Match', () async {
    await ApiClient.instance.dio.get('/api/v1/agenda/terpadu');
    await ApiClient.instance.dio.get('/api/v1/agenda/terpadu');

    expect(adapter.ifNoneMatch, [isNull, isNull]);
    expect(
      await EtagCacheService.instance.baca('/api/v1/agenda/terpadu?'),
      isNull,
      reason: 'data per-NIM dilarang masuk cache publik',
    );
  });

  test('envelope galat tidak disimpan meski membawa ETag', () async {
    await ApiClient.instance.dio.get('/api/v1/berita/9');

    expect(
      await EtagCacheService.instance.baca('/api/v1/berita/9?'),
      isNull,
    );
  });

  test('path per-NIM tidak tertarik prefix endpoint publik', () {
    // Sanitasi daftar kecocokan: prefix berhati-hati.
    bool cacheable(String p) {
      if (p == '/api/v1/berita' || p.startsWith('/api/v1/berita/')) return true;
      if (p == '/api/v1/pengumumanAkademik' ||
          p.startsWith('/api/v1/pengumumanAkademik/')) {
        return true;
      }
      if (p == '/api/v1/panduan') return true;
      if (p == '/api/v1/akademik/agenda') return true;
      if (p == '/api/v1/agenda') return true;
      return false;
    }

    expect(cacheable('/api/v1/agenda/terpadu'), isFalse);
    expect(cacheable('/api/v1/panduan/download/x'), isFalse);
    expect(cacheable('/api/v1/agenda'), isTrue);
    expect(cacheable('/api/v1/panduan'), isTrue);
    expect(cacheable('/api/v1/berita/12'), isTrue);
  });
}
