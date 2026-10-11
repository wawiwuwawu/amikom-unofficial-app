import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_amikom/services/nilai_service.dart';

void main() {
  group('NilaiService contract & endpoints', () {
    test('getRincianNilai handles queryParams and returns RincianNilaiResponse', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, equals('/api/v1/nilai/rincian'));
          expect(options.queryParameters['thn_akademik'], equals('2025/2026'));
          expect(options.queryParameters['semester'], equals('1'));
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'thn_akademik': '2025/2026',
              'semester_id': '1',
              'semester_label': 'Semester 1',
              'thn_aktif': '2025/2026',
              'data': [],
              'rentang_nilai': [],
            },
          ));
        },
      ));

      final service = NilaiService(dio: dio);
      final res = await service.getRincianNilai(thnAkademik: '2025/2026', semester: '1');
      expect(res.thnAkademik, equals('2025/2026'));
      expect(res.semesterId, equals('1'));
    });

    test('getTahunAkademikList unwrapData and returns list of NilaiOpsiItem', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, equals('/api/v1/nilai/tahun-akademik'));
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'data': [
                {'value': '2025/2026', 'label': '2025/2026'},
                {'value': '2024/2025', 'label': '2024/2025'},
              ],
            },
          ));
        },
      ));

      final service = NilaiService(dio: dio);
      final list = await service.getTahunAkademikList();
      expect(list.length, equals(2));
      expect(list[0].value, equals('2025/2026'));
      expect(list[1].value, equals('2024/2025'));
    });

    test('getSemesterList unwrapData and returns list of NilaiOpsiItem', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, equals('/api/v1/nilai/semester'));
          expect(options.queryParameters['thn_akademik'], equals('2025/2026'));
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'data': [
                {'value': '1', 'label': 'Semester Ganjil'},
                {'value': '2', 'label': 'Semester Genap'},
              ],
            },
          ));
        },
      ));

      final service = NilaiService(dio: dio);
      final list = await service.getSemesterList(thnAkademik: '2025/2026');
      expect(list.length, equals(2));
      expect(list[0].value, equals('1'));
      expect(list[1].label, equals('Semester Genap'));
    });
  });
}
