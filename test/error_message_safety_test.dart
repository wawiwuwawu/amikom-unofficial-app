// Kontrak pesan galat: pengguna TIDAK PERNAH melihat detail teknis.
//
// Bug yang dijaga: `ApiClient.handleError` pernah mengembalikan
// `Exception(e.toString())` untuk semua error non-Dio, dan halaman menampilkan
// `e.toString()` langsung — sehingga "FormatException: Unexpected character"
// atau "type 'Null' is not a subtype of …" bisa tampil di layar.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_amikom/models/app_failure.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/widgets/app_kit.dart';

DioException _dioError(int status, dynamic body) => DioException(
      requestOptions: RequestOptions(path: '/api/v1/uji'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/v1/uji'),
        statusCode: status,
        data: body,
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  group('ApiClient.handleError tidak membocorkan detail teknis', () {
    test('error non-Dio diganti pesan fallback ramah', () {
      final leaks = <Object>[
        FormatException('Unexpected character (at character 1 of JSON data)'),
        TypeError(),
        ArgumentError('Invalid argument(s): No host specified in URI'),
        Exception('Exception: type Null is not a subtype of Map<String, dynamic>'),
        Exception('PlatformException(channel-error, ...)'),
      ];

      for (final error in leaks) {
        final failure = ApiClient.handleError(error, 'Gagal memuat data');

        expect(failure.message, 'Gagal memuat data');
        // toString() wajib aman karena masih dipakai di beberapa halaman.
        expect(failure.toString(), 'Gagal memuat data');
        for (final marker in ['Exception', 'Null', 'Format', 'PlatformException']) {
          expect(failure.toString(), isNot(contains(marker)));
        }
      }
    });

    test('pesan server yang mengandung jejak teknis diganti fallback', () {
      final error = _dioError(400, {
        'message': 'TypeError: Cannot read properties of undefined (reading x)',
      });

      // 400 tanpa pesan server yang layak → pesan 400 yang ramah (bukan teks server).
      final message = ApiClient.handleError(error, 'Gagal menyimpan data').message;
      expect(message, 'Permintaan tidak valid');
      expect(message, isNot(contains('TypeError')));
      expect(message, isNot(contains('undefined')));
    });

    test('pesan server yang ramah tetap diteruskan', () {
      final error = _dioError(400, {
        'message': 'Nama file tidak boleh memuat karakter khusus',
      });

      expect(
        ApiClient.handleError(error, 'Gagal menyimpan data').message,
        'Nama file tidak boleh memuat karakter khusus',
      );
    });

    test('sesi berakhir selalu diarahkan login ulang', () {
      expect(
        ApiClient.handleError(_dioError(401, null), 'Gagal').message,
        'Sesi berakhir. Silakan login ulang.',
      );
    });

    test('AppFailure yang sudah ramah tidak ditimpa', () {
      const failure = AppFailure('Data pendaftaran belum tersedia');

      expect(ApiClient.handleError(failure, 'Gagal'), same(failure));
    });
  });

  group('userErrorMessage aman untuk semua jenis error', () {
    test('error mentah apa pun menjadi pesan fallback', () {
      expect(userErrorMessage(FormatException('boom'), 'Gagal memuat'), 'Gagal memuat');
      expect(userErrorMessage(TypeError(), 'Gagal memuat'), 'Gagal memuat');
      expect(userErrorMessage(null, 'Gagal memuat'), 'Gagal memuat');
      expect(userErrorMessage('apa saja', 'Gagal memuat'), 'Gagal memuat');
    });

    test('pesan AppFailure dipakai apa adanya', () {
      expect(
        userErrorMessage(const AppFailure('Koneksi terputus. Periksa jaringan Anda.')),
        'Koneksi terputus. Periksa jaringan Anda.',
      );
    });
  });

  group('AppFailure.fromServer', () {
    test('menyaring teks teknis dan memakai fallback', () {
      expect(
        AppFailure.fromServer('SQLSTATE[42S02]: Base table not found').message,
        'Terjadi kesalahan',
      );
      expect(
        AppFailure.fromServer('<!DOCTYPE html><html><body>500</body></html>').message,
        'Terjadi kesalahan',
      );
    });

    test('pesan kosong memakai fallback', () {
      expect(AppFailure.fromServer(null, fallback: 'Gagal').message, 'Gagal');
      expect(AppFailure.fromServer('   ', fallback: 'Gagal').message, 'Gagal');
    });
  });
}
