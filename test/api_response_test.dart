import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_amikom/models/api_response.dart';
import 'package:app_amikom/services/api_client.dart';

void main() {
  group('MutationResult', () {
    test('MutationResult parses success & failure', () {
      final successRes = MutationResult.fromJson({
        'status': 'success',
        'message': 'Berhasil simpan',
        'data': {'id': 1},
      });
      expect(successRes.success, isTrue);
      expect(successRes.message, equals('Berhasil simpan'));
      expect(() => successRes.ensureSuccess(), returnsNormally);

      final failRes = MutationResult.fromJson({
        'status': 'error',
        'message': 'Gagal simpan',
      });
      expect(failRes.success, isFalse);
      expect(failRes.message, equals('Gagal simpan'));
      expect(() => failRes.ensureSuccess(), throwsException);
    });
    test('MutationResult treats status: success with success: false as failure', () {
      final rejectedRes = MutationResult.fromJson({
        'status': 'success',
        'data': null,
        'success': false,
        'message': 'Validasi berkas ditolak portal',
      });
      expect(rejectedRes.success, isFalse);
      expect(rejectedRes.message, equals('Validasi berkas ditolak portal'));
      expect(() => rejectedRes.ensureSuccess(), throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('Validasi berkas ditolak portal'))));
    });
    test('MutationResult operator [] accesses properties and rawRoot', () {
      final res = MutationResult.fromJson({
        'status': 'success',
        'message': 'Data berhasil disimpan',
        'data': {'id': 99},
        'custom_key': 'custom_value',
      });
      expect(res['message'], equals('Data berhasil disimpan'));
      expect(res['success'], isTrue);
      expect(res['data'], equals({'id': 99}));
      expect(res['custom_key'], equals('custom_value'));
      expect(res['non_existent'], isNull);
    });
  });

  group('ApiClient unwrap helpers', () {
    test('unwrapData returns unwrapped data if envelope', () {
      final data = ApiClient.unwrapData<Map<String, dynamic>>({
        'status': 'success',
        'data': {'nim': '20.11.1234'},
      });
      expect(data['nim'], equals('20.11.1234'));
    });

    test('unwrapData returns direct data if not envelope', () {
      final data = ApiClient.unwrapData<Map<String, dynamic>>({
        'nim': '20.11.1234',
      });
      expect(data['nim'], equals('20.11.1234'));
    });

    test('unwrapRoot returns valid map or throws', () {
      final root = ApiClient.unwrapRoot({'status': 'success', 'data': 123});
      expect(root['status'], equals('success'));

      expect(
        () => ApiClient.unwrapRoot({'status': 'error', 'message': 'Terjadi kesalahan'}),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('Terjadi kesalahan'))),
      );
    });

    test('unwrapMutation returns MutationResult and ensures success', () {
      final res = ApiClient.unwrapMutation({'status': 'success', 'message': 'OK'});
      expect(res.success, isTrue);
      expect(res.message, equals('OK'));

      expect(
        () => ApiClient.unwrapMutation({'status': 'error', 'message': 'Gagal validasi'}),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('Gagal validasi'))),
      );
    });
  });

  group('ApiClient.handleError status code mapping', () {
    test('maps 400 with custom message or default', () {
      final e1 = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 400,
          data: {'message': 'NIM wajib diisi'},
        ),
      );
      expect(ApiClient.handleError(e1).toString(), contains('NIM wajib diisi'));

      final e2 = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 400,
        ),
      );
      expect(ApiClient.handleError(e2).toString(), contains('Permintaan tidak valid'));
    });

    test('maps 401', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 401,
        ),
      );
      expect(ApiClient.handleError(e).toString(), contains('Sesi berakhir. Silakan login ulang.'));
    });

    test('maps 413', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 413,
        ),
      );
      expect(ApiClient.handleError(e).toString(), contains('Ukuran berkas melebihi batas 5 MB'));
    });

    test('maps 429', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 429,
        ),
      );
      expect(ApiClient.handleError(e).toString(), contains('Terlalu banyak permintaan. Silakan tunggu sebentar.'));
    });

    test('maps 500 session expired vs server error', () {
      final e1 = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 500,
          data: {'message': 'Sesi Anda telah kedaluwarsa'},
        ),
      );
      expect(ApiClient.handleError(e1).toString(), contains('Sesi berakhir. Silakan login ulang.'));

      final e2 = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 500,
          data: {'message': 'Internal database error'},
        ),
      );
      expect(ApiClient.handleError(e2).toString(), contains('Terjadi kendala pada server portal'));
    });

    test('maps 502/503/504', () {
      for (final code in [502, 503, 504]) {
        final e = DioException(
          requestOptions: RequestOptions(path: '/'),
          response: Response(
            requestOptions: RequestOptions(path: '/'),
            statusCode: code,
          ),
        );
        expect(ApiClient.handleError(e).toString(), contains('Layanan portal Amikom sedang tidak dapat diakses'));
      }
    });
  });
}
