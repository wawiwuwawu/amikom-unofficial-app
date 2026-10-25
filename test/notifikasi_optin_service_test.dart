import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/models/app_failure.dart';
import 'package:app_amikom/models/notifikasi.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/notifikasi_service.dart';

class _MockReply {
  final int statusCode;
  final Map<String, dynamic> body;
  final Map<String, List<String>> headers;

  const _MockReply({
    this.statusCode = 200,
    required this.body,
    this.headers = const {},
  });
}

class _FakeOptinAdapter implements HttpClientAdapter {
  _FakeOptinAdapter(this._handler);

  final _MockReply Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final reply = _handler(options);
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...reply.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000\n');
  });

  group('NotifikasiService push FCM', () {
    late NotifikasiService service;

    setUp(() {
      service = NotifikasiService();
    });

    test('GET optin mengekspos enabled dan token_count', () async {
      RequestOptions? captured;
      ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter((options) {
        captured = options;
        return const _MockReply(
          body: {
            'status': 'success',
            'data': {'enabled': true, 'token_count': 3},
          },
        );
      });

      final status = await service.getOptinStatus();

      expect(captured?.method, equals('GET'));
      expect(captured?.path, equals('/api/v1/notifikasi/optin'));
      expect(status.enabled, isTrue);
      expect(status.tokenCount, equals(3));
    });

    test('GET optin saat fitur nonaktif menghasilkan enabled false', () async {
      ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter((_) {
        return const _MockReply(
          body: {
            'status': 'success',
            'data': {'enabled': false, 'token_count': 0},
          },
        );
      });

      final status = await service.getOptinStatus();

      expect(status.enabled, isFalse);
      expect(status.tokenCount, equals(0));
    });

    test('GET optin token_count non-numerik jatuh ke 0 tanpa melempar', () async {
      ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter((_) {
        return const _MockReply(
          body: {
            'status': 'success',
            'data': {'enabled': true, 'token_count': 'bukan-angka'},
          },
        );
      });

      final status = await service.getOptinStatus();

      expect(status.enabled, isTrue);
      expect(status.tokenCount, equals(0));
    });

    test(
      'POST device-token mengirim token + platform dan mengembalikan status',
      () async {
        RequestOptions? captured;
        ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter((
          options,
        ) {
          captured = options;
          return const _MockReply(
            body: {
              'status': 'success',
              'success': true,
              'message': 'Token perangkat terdaftar',
              'data': {'enabled': true, 'token_count': 1},
            },
          );
        });

        final status = await service.daftarkanToken('fcm-token-ujicoba');

        expect(captured?.method, equals('POST'));
        expect(
          captured?.path,
          equals('/api/v1/notifikasi/device-token'),
        );
        expect(captured?.data, isA<Map<String, dynamic>>());
        expect(
          (captured?.data as Map<String, dynamic>)['token'],
          equals('fcm-token-ujicoba'),
        );
        expect(
          (captured?.data as Map<String, dynamic>)['platform'],
          equals('android'),
        );
        expect(status.enabled, isTrue);
        expect(status.tokenCount, equals(1));
      },
    );

    test(
      'POST device-token 503 melempar AppFailure pesan ramah fitur dinonaktifkan',
      () async {
        ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter((_) {
          return const _MockReply(
            statusCode: 503,
            body: {'status': 'error', 'message': 'Service Unavailable'},
          );
        });

        await expectLater(
          () => service.daftarkanToken('fcm-token-ujicoba'),
          throwsA(
            isA<AppFailure>().having(
              (e) => e.message,
              'message',
              equals(
                'Layanan notifikasi push sedang dinonaktifkan oleh server.',
              ),
            ),
          ),
        );
      },
    );

    test(
      'POST device-token 429 dengan Retry-After: 42 melempar NotifikasiRateLimited(42)',
      () async {
        ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter((_) {
          return const _MockReply(
            statusCode: 429,
            headers: {
              'Retry-After': ['42'],
            },
            body: {'status': 'error', 'message': 'Too Many Requests'},
          );
        });

        await expectLater(
          () => service.daftarkanToken('fcm-token-ujicoba'),
          throwsA(
            isA<NotifikasiRateLimited>()
                .having((e) => e.retryAfterSeconds, 'retryAfterSeconds', 42)
                .having(
                  (e) => e.message,
                  'message',
                  'Terlalu banyak permintaan. Coba lagi dalam 42 detik.',
                ),
          ),
        );
      },
    );

    test('POST device-token 429 tanpa header Retry-After jatuh ke 60 detik', () async {
      ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter((_) {
        return const _MockReply(
          statusCode: 429,
          body: {'status': 'error', 'message': 'Too Many Requests'},
        );
      });

      await expectLater(
        () => service.daftarkanToken('fcm-token-ujicoba'),
        throwsA(
          isA<NotifikasiRateLimited>().having(
            (e) => e.retryAfterSeconds,
            'retryAfterSeconds',
            60,
          ),
        ),
      );
    });

    test(
      'DELETE device-token dengan token hanya menghapus token tersebut',
      () async {
        RequestOptions? captured;
        ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter((
          options,
        ) {
          captured = options;
          return const _MockReply(
            body: {
              'status': 'success',
              'data': null,
              'success': true,
              'message': 'Token perangkat dihapus',
            },
          );
        });

        await service.hapusToken('fcm-token-ujicoba');

        expect(captured?.method, equals('DELETE'));
        expect(captured?.path, equals('/api/v1/notifikasi/device-token'));
        expect(captured?.data, isA<Map<String, dynamic>>());
        expect(
          (captured?.data as Map<String, dynamic>)['token'],
          equals('fcm-token-ujicoba'),
        );
      },
    );

    test(
      'DELETE device-token dengan token kosong menghapus semua token',
      () async {
        RequestOptions? captured;
        ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter((
          options,
        ) {
          captured = options;
          return const _MockReply(
            body: {
              'status': 'success',
              'data': null,
              'success': true,
              'message': 'Semua token perangkat dihapus',
            },
          );
        });

        await service.hapusToken('');

        expect(captured?.method, equals('DELETE'));
        expect(captured?.path, equals('/api/v1/notifikasi/device-token'));
        expect(captured?.data, isNull);
      },
    );

    test(
      'DELETE device-token idempoten walau token sudah tidak ada',
      () async {
        ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter((_) {
          return const _MockReply(
            body: {
              'status': 'success',
              'data': null,
              'success': true,
              'message': 'Token perangkat dihapus',
            },
          );
        });

        // `returnsNormally` TIDAK menunggu future hasil closure — request
        // DELETE bocor melewati akhir test dan di runner CI yang lambat
        // future-nya selesai SETELAH test ditutup ("failed after test
        // completion", flaky). Tunggu future-nya secara langsung.
        await service.hapusToken('fcm-token-yang-tidak-ada');
      },
    );

    test(
      'DELETE device-token 503 memakai pesan ramah yang sama',
      () async {
        ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter((_) {
          return const _MockReply(
            statusCode: 503,
            body: {'status': 'error', 'message': 'Service Unavailable'},
          );
        });

        await expectLater(
          () => service.hapusToken('fcm-token-ujicoba'),
          throwsA(
            isA<AppFailure>().having(
              (e) => e.message,
              'message',
              equals(
                'Layanan notifikasi push sedang dinonaktifkan oleh server.',
              ),
            ),
          ),
        );
      },
    );

    test(
      '404 detail notifikasi dipetakan ke pesan server yang ramah',
      () async {
        ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter(
          (options) => const _MockReply(
            statusCode: 404,
            body: {'status': 'error', 'message': 'Notifikasi tidak ditemukan'},
          ),
        );

        await expectLater(
          service.getNotifikasiDetail('999'),
          throwsA(
            isA<AppFailure>().having(
              (e) => e.message,
              'message',
              'Notifikasi tidak ditemukan',
            ),
          ),
        );
      },
    );

    test('404 detail tanpa pesan server memakai redaksi bawaan', () async {
      ApiClient.instance.dio.httpClientAdapter = _FakeOptinAdapter(
        (options) => const _MockReply(statusCode: 404, body: {}),
      );

      await expectLater(
        service.getNotifikasiDetail('998'),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.message,
            'message',
            'Notifikasi tidak ditemukan atau sudah dihapus',
          ),
        ),
      );
    });

    test('404 global tidak lagi dibajak oleh redaksi notifikasi', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/v1/khs/download'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/khs/download'),
          statusCode: 404,
          data: Uint8List(0),
        ),
        type: DioExceptionType.badResponse,
      );

      final failure = ApiClient.handleError(err, 'Gagal mengunduh KHS');

      expect(
        failure.message,
        equals('Gagal mengunduh KHS'),
        reason: 'unduhan PDF lain tidak boleh memakai redaksi notifikasi',
      );
    });
  });

  group('ApiClient.canRenewAndRetry', () {
    test('mengizinkan method aman dan mutasi idempoten device-token', () {
      expect(ApiClient.canRenewAndRetry('GET', '/api/v1/notifikasi'), isTrue);
      expect(ApiClient.canRenewAndRetry('head', '/health'), isTrue);
      expect(
        ApiClient.canRenewAndRetry('POST', '/api/v1/notifikasi/device-token'),
        isTrue,
      );
      expect(
        ApiClient.canRenewAndRetry('DELETE', '/api/v1/notifikasi/device-token'),
        isTrue,
      );
    });

    test('menolak mutasi non-idempoten', () {
      expect(
        ApiClient.canRenewAndRetry('POST', '/api/v1/keuangan/tagihan/bayar'),
        isFalse,
      );
      expect(
        ApiClient.canRenewAndRetry('DELETE', '/api/v1/skripsi/bimbingan'),
        isFalse,
      );
      expect(
        ApiClient.canRenewAndRetry('PUT', '/api/v1/notifikasi/device-token'),
        isFalse,
      );
      expect(
        ApiClient.canRenewAndRetry('POST', '/api/v1/notifikasi/device-token/extra'),
        isFalse,
      );
    });
  });

  group('ApiClient identitas (nim) di secure storage', () {
    test('restoreSession memulihkan nim setelah cold start', () async {
      FlutterSecureStorage.setMockInitialValues({
        'token': 'token-uji',
        'refreshToken': 'refresh-uji',
        'nim': '21.11.0777',
        'nama': 'Mahasiswa Uji',
      });

      await ApiClient.instance.restoreSession();

      expect(ApiClient.instance.nim, '21.11.0777');
      expect(ApiClient.instance.nama, 'Mahasiswa Uji');
    });

    test('setUserInfo menulis nim sehingga bertahan restart', () async {
      FlutterSecureStorage.setMockInitialValues({});

      await ApiClient.instance.setUserInfo('21.11.0779', 'Mahasiswa Uji');

      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'nim'), '21.11.0779');
      expect(ApiClient.instance.nim, '21.11.0779');
    });

    test('clearTokens membuang nim dari memori dan storage', () async {
      FlutterSecureStorage.setMockInitialValues({
        'token': 'token-uji',
        'refreshToken': 'refresh-uji',
        'nim': '21.11.0778',
      });
      await ApiClient.instance.restoreSession();

      await ApiClient.instance.clearTokens();

      expect(ApiClient.instance.nim, isNull);
      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'nim'), isNull);
    });
  });

  group('NotifikasiService read_notification_ids per-NIM & pemangkasan', () {
    late NotifikasiService service;

    setUp(() {
      service = NotifikasiService();
    });

    test(
      'markAllAsRead menyimpan SEMUA id walau daftar > 200 (tak ada unread palsu)',
      () async {
        SharedPreferences.setMockInitialValues({});
        ApiClient.instance.setUserInfo('21.11.0002', 'Mahasiswa Uji');

        // Daftar dari BE terbaru-di-atas: id-325 (terbaru) ... id-1 (terlama).
        final ids = List<String>.generate(325, (i) => 'id-${325 - i}');
        await service.markAllAsRead(ids);

        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getStringList('read_notification_ids_21.11.0002');
        expect(stored, isNotNull);
        expect(stored!.length, equals(325));

        final readSet = await service.getReadIds();
        expect(readSet.length, equals(325));
        // Item terbaru TIDAK boleh hilang (regresi bug cap 200).
        expect(readSet.contains('id-325'), isTrue);
        expect(readSet.contains('id-1'), isTrue);
      },
    );

    test(
      'tandai-semua berulang tidak membuat item yang baru dibaca balik jadi Baru',
      () async {
        SharedPreferences.setMockInitialValues({});
        ApiClient.instance.setUserInfo('21.11.0003', 'Mahasiswa Uji');

        final ids = List<String>.generate(325, (i) => 'id-${325 - i}');
        await service.markAllAsRead(ids);
        // Baca satu item terbaru, lalu tekan "Tandai Dibaca" lagi.
        await service.markAsRead('id-325');
        await service.markAllAsRead(ids);

        final readSet = await service.getReadIds();
        expect(readSet.length, equals(325));
        expect(readSet.contains('id-325'), isTrue);
        expect(readSet.contains('id-1'), isTrue);
      },
    );

    test(
      'migrasi sekali menyalin kunci lama ke kunci per-NIM lalu menghapus kunci lama',
      () async {
        SharedPreferences.setMockInitialValues({
          'read_notification_ids': ['lama-1', 'lama-2'],
        });
        ApiClient.instance.setUserInfo('21.11.0002', 'Mahasiswa Dua');

        await service.markAsRead('baru-3');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('read_notification_ids'), isFalse);
        expect(
          prefs.getStringList('read_notification_ids_21.11.0002'),
          equals(['lama-1', 'lama-2', 'baru-3']),
        );
      },
    );

    test(
      'bila NIM belum tersedia, status baca memakai kunci lama (hasil upgrade)',
      () async {
        SharedPreferences.setMockInitialValues({
          'read_notification_ids': ['lama-1'],
        });
        ApiClient.instance.setUserInfo('', '');

        await service.markAsRead('baru-2');

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList('read_notification_ids'),
          equals(['lama-1', 'baru-2']),
          reason:
              'tanpa NIM, jangan menulis ke kunci per-NIM dan jangan menghapus kunci lama',
        );
        expect(await service.getReadIds(), contains('lama-1'));
        expect(
          prefs.getKeys().where(
            (key) => key.startsWith('read_notification_ids_'),
          ),
          isEmpty,
        );
      },
    );
  });
}
