import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/skripsi_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000\n');
  });

  group('SkripsiService.submitProposalBaru', () {
    late Directory tempDir;
    late SkripsiService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('skripsi_test_');
      service = SkripsiService();
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('validasi lokal: menolak nama file yang memuat karakter khusus (&, ", \', <, >)', () async {
      final invalidNames = [
        'proposal&revisi.pdf',
        'proposal"final.pdf',
        "proposal'v1.pdf",
        'proposal<final>.pdf',
        'proposal>v2.pdf',
      ];

      for (final name in invalidNames) {
        // Menggunakan File virtual tanpa writeAsBytes agar kompatibel dengan filesystem Windows NTFS
        final file = File('${tempDir.path}/$name');

        expect(
          () => service.submitProposalBaru(
            judul: 'Sistem Informasi Skripsi',
            filePdf: file,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Nama file tidak boleh memuat karakter khusus'),
            ),
          ),
          reason: 'Gagal mendeteksi karakter terlarang pada nama: $name',
        );
      }
    });

    test('validasi lokal: menolak ukuran file lebih dari 3 MB', () async {
      final largeFile = File('${tempDir.path}/proposal_besar.pdf');
      // Buat file 3 MB + 1 byte
      final largeBytes = List<int>.filled(3 * 1024 * 1024 + 1, 0);
      await largeFile.writeAsBytes(largeBytes);

      expect(
        () => service.submitProposalBaru(
          judul: 'Sistem Informasi Skripsi',
          filePdf: largeFile,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Ukuran file maksimal 3 MB'),
          ),
        ),
      );
    });

    test('berhasil mengirim proposal dengan FormData (judul & file) dan mengembalikan MutationResult', () async {
      final validFile = File('${tempDir.path}/valid_proposal.pdf');
      await validFile.writeAsBytes([1, 2, 3, 4, 5]);
      RequestOptions? capturedOptions;
      final interceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/api/v1/skripsi/proposal' && options.method == 'POST') {
            capturedOptions = options;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'message': 'Proposal berhasil diajukan',
                  'data': {'id': 99},
                },
              ),
            );
          }
          return handler.next(options);
        },
      );

      ApiClient.instance.dio.interceptors.insert(0, interceptor);

      try {
        final result = await service.submitProposalBaru(
          judul: '  Rancang Bangun Aplikasi Mobile Amikom  ',
          filePdf: validFile,
        );

        expect(result.success, isTrue);
        expect(result.message, equals('Proposal berhasil diajukan'));
        expect(result.data, equals({'id': 99}));

        expect(capturedOptions, isNotNull);
        expect(capturedOptions!.method, equals('POST'));
        expect(capturedOptions!.path, equals('/api/v1/skripsi/proposal'));

        final formData = capturedOptions!.data;
        expect(formData, isA<FormData>());
        final fd = formData as FormData;

        // Cek field judul di-trim
        final judulField = fd.fields.firstWhere((f) => f.key == 'judul');
        expect(judulField.value, equals('Rancang Bangun Aplikasi Mobile Amikom'));

        // Cek file multipart
        final fileEntry = fd.files.firstWhere((f) => f.key == 'file');
        expect(fileEntry.value.filename, equals('valid_proposal.pdf'));
      } finally {
        ApiClient.instance.dio.interceptors.remove(interceptor);
      }
    });

    test('menangani error backend (DioException) dengan memetakan pesan kesalahan', () async {
      final validFile = File('${tempDir.path}/valid_proposal.pdf');
      await validFile.writeAsBytes([1, 2, 3, 4, 5]);

      final errorInterceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/api/v1/skripsi/proposal') {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 400,
                  data: <String, dynamic>{
                    'status': 'error',
                    'message': 'Mahasiswa sudah memiliki proposal aktif',
                  },
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          }
          return handler.next(options);
        },
      );

      ApiClient.instance.dio.interceptors.insert(0, errorInterceptor);

      try {
        await service.submitProposalBaru(
          judul: 'Proposal Ulang',
          filePdf: validFile,
        );
        fail('Harusnya melempar exception');
      } catch (e) {
        expect(
          e.toString(),
          contains('Mahasiswa sudah memiliki proposal aktif'),
        );
      } finally {
        ApiClient.instance.dio.interceptors.remove(errorInterceptor);
      }
    });
  });
}
