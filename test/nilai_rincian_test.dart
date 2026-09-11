import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_amikom/models/agenda.dart';
import 'package:app_amikom/models/nilai_rincian.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/nilai_service.dart';

void main() {
  group('Agenda Model', () {
    test('parses uppercase keys correctly', () {
      final json = {
        'TITLE': 'Wisuda Periode 80',
        'MULAI': '2026-10-01',
        'SELESAI': '2026-10-02',
      };
      final agenda = Agenda.fromJson(json);
      expect(agenda.title, equals('Wisuda Periode 80'));
      expect(agenda.mulai, equals('2026-10-01'));
      expect(agenda.selesai, equals('2026-10-02'));
    });

    test('parses lowercase keys correctly', () {
      final json = {
        'title': 'KRS Online Semester Genap',
        'mulai': '2026-02-01',
        'selesai': '2026-02-14',
      };
      final agenda = Agenda.fromJson(json);
      expect(agenda.title, equals('KRS Online Semester Genap'));
      expect(agenda.mulai, equals('2026-02-01'));
      expect(agenda.selesai, equals('2026-02-14'));
    });

    test('handles fallback when mixed or missing', () {
      final json = <String, dynamic>{};
      final agenda = Agenda.fromJson(json);
      expect(agenda.title, isEmpty);
      expect(agenda.mulai, isEmpty);
      expect(agenda.selesai, isEmpty);
    });
  });

  group('Nilai Rincian Models', () {
    test('NilaiOpsiItem parses value and label', () {
      final json = {'value': '2025/2026', 'label': '2025/2026 Ganjil'};
      final item = NilaiOpsiItem.fromJson(json);
      expect(item.value, equals('2025/2026'));
      expect(item.label, equals('2025/2026 Ganjil'));
    });

    test('MatkulNilaiItem parses nested nilai map, NA, and NH', () {
      final json = {
        'kode': 'IF001',
        'nama': 'Pemrograman Mobile',
        'nilai': {
          'Tugas': 85,
          'UTS': 80,
          'UAS': 90,
          'Responsi': 95,
        },
        'nilai_akhir': '86.5',
        'nilai_huruf': 'A',
      };
      final matkul = MatkulNilaiItem.fromJson(json);
      expect(matkul.kode, equals('IF001'));
      expect(matkul.nama, equals('Pemrograman Mobile'));
      expect(matkul.nilai['Tugas'], equals(85));
      expect(matkul.nilai['UAS'], equals(90));
      expect(matkul.nilaiAkhir, equals('86.5'));
      expect(matkul.nilaiHuruf, equals('A'));
    });

    test('KelompokNilaiItem parses reguler and mbkm groups', () {
      final json = {
        'jenis': 'reguler',
        'kolom': ['Tugas', 'UTS', 'UAS'],
        'matkul': [
          {
            'kode': 'IF001',
            'nama': 'Pemrograman Mobile',
            'nilai': {'Tugas': 80, 'UTS': 85, 'UAS': 90},
            'nilai_akhir': '85',
            'nilai_huruf': 'A',
          }
        ],
      };
      final kelompok = KelompokNilaiItem.fromJson(json);
      expect(kelompok.jenis, equals('reguler'));
      expect(kelompok.kolom, equals(['Tugas', 'UTS', 'UAS']));
      expect(kelompok.matkul.length, equals(1));
      expect(kelompok.matkul.first.nama, equals('Pemrograman Mobile'));
    });

    test('RentangNilaiItem parses range, letter grade, and weight', () {
      final json = {
        'rentang': '81 - 100',
        'huruf': 'A',
        'bobot': '4.00',
      };
      final rentang = RentangNilaiItem.fromJson(json);
      expect(rentang.rentang, equals('81 - 100'));
      expect(rentang.huruf, equals('A'));
      expect(rentang.bobot, equals('4.00'));
    });

    test('RincianNilaiResponse unwrapRoot & parses full envelope', () {
      final payload = {
        'status': 'success',
        'message': 'Data rincian nilai berhasil diambil',
        'thn_akademik': '2025/2026',
        'semester_id': '1',
        'semester_label': 'Semester Ganjil',
        'thn_aktif': '2025/2026',
        'data': [
          {
            'jenis': 'reguler',
            'kolom': ['Tugas', 'UTS', 'UAS'],
            'matkul': [
              {
                'kode': 'IF002',
                'nama': 'Basis Data Lanjut',
                'nilai': {'Tugas': 90, 'UTS': 85, 'UAS': 88},
                'nilai_akhir': '87.5',
                'nilai_huruf': 'A',
              }
            ],
          },
          {
            'jenis': 'mbkm',
            'kolom': ['Konversi'],
            'matkul': [
              {
                'kode': 'MB001',
                'nama': 'Studi Independen',
                'nilai': {'Konversi': 100},
                'nilai_akhir': '100',
                'nilai_huruf': 'A',
              }
            ],
          }
        ],
        'rentang_nilai': [
          {'rentang': '81 - 100', 'huruf': 'A', 'bobot': '4.00'},
          {'rentang': '61 - 80', 'huruf': 'B', 'bobot': '3.00'},
          {'rentang': '41 - 60', 'huruf': 'C', 'bobot': '2.00'},
          {'rentang': '21 - 40', 'huruf': 'D', 'bobot': '1.00'},
          {'rentang': '0 - 20', 'huruf': 'E', 'bobot': '0.00'},
        ],
      };

      final root = ApiClient.unwrapRoot(payload);
      final response = RincianNilaiResponse.fromJson(root);

      expect(response.thnAkademik, equals('2025/2026'));
      expect(response.semesterId, equals('1'));
      expect(response.semesterLabel, equals('Semester Ganjil'));
      expect(response.thnAktif, equals('2025/2026'));
      expect(response.kelompok.length, equals(2));
      expect(response.kelompok[0].jenis, equals('reguler'));
      expect(response.kelompok[0].matkul.first.kode, equals('IF002'));
      expect(response.kelompok[1].jenis, equals('mbkm'));
      expect(response.kelompok[1].matkul.first.kode, equals('MB001'));
      expect(response.rentangNilai.length, equals(5));
      expect(response.rentangNilai.first.huruf, equals('A'));
    });
  });

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
