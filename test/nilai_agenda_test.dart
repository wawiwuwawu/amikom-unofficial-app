import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_amikom/models/agenda.dart';
import 'package:app_amikom/models/nilai_rincian.dart';
import 'package:app_amikom/pages/login_page.dart';
import 'package:app_amikom/services/api_client.dart';
void main() {
  group('Agenda.fromJson Tests (Fase 5 & 6)', () {
    test('parses lowercase keys correctly', () {
      final json = {
        'title': 'Pertemuan Tatap Muka Matakuliah',
        'mulai': '2026-03-01 08:00',
        'selesai': '2026-03-01 10:00',
      };

      final agenda = Agenda.fromJson(json);

      expect(agenda.title, equals('Pertemuan Tatap Muka Matakuliah'));
      expect(agenda.mulai, equals('2026-03-01 08:00'));
      expect(agenda.selesai, equals('2026-03-01 10:00'));
    });

    test('parses uppercase keys correctly (legacy fallback)', () {
      final json = {
        'TITLE': 'Ujian Akhir Semester (UAS)',
        'MULAI': '2026-07-10',
        'SELESAI': '2026-07-25',
      };

      final agenda = Agenda.fromJson(json);

      expect(agenda.title, equals('Ujian Akhir Semester (UAS)'));
      expect(agenda.mulai, equals('2026-07-10'));
      expect(agenda.selesai, equals('2026-07-25'));
    });

    test('handles empty or missing keys gracefully with default empty string', () {
      final json = <String, dynamic>{};

      final agenda = Agenda.fromJson(json);

      expect(agenda.title, equals(''));
      expect(agenda.mulai, equals(''));
      expect(agenda.selesai, equals(''));
    });

    test('prioritizes lowercase over uppercase when both exist', () {
      final json = {
        'title': 'Prioritas Huruf Kecil',
        'TITLE': 'Abaikan Huruf Besar',
        'mulai': '2026-04-01',
        'MULAI': '2026-01-01',
        'selesai': '2026-04-02',
        'SELESAI': '2026-01-02',
      };

      final agenda = Agenda.fromJson(json);

      expect(agenda.title, equals('Prioritas Huruf Kecil'));
      expect(agenda.mulai, equals('2026-04-01'));
      expect(agenda.selesai, equals('2026-04-02'));
    });
  });

  group('NilaiOpsiItem Tests', () {
    test('parses standard value and label correctly', () {
      final json = {
        'value': '2025/2026',
        'label': '2025/2026 Ganjil',
      };

      final item = NilaiOpsiItem.fromJson(json);

      expect(item.value, equals('2025/2026'));
      expect(item.label, equals('2025/2026 Ganjil'));
      expect(item.toJson(), equals({'value': '2025/2026', 'label': '2025/2026 Ganjil'}));
    });

    test('parses alternative keys id/kode and nama/text', () {
      final jsonKode = {'kode': '2024/2025', 'nama': 'Tahun 2024/2025'};
      final item1 = NilaiOpsiItem.fromJson(jsonKode);
      expect(item1.value, equals('2024/2025'));
      expect(item1.label, equals('Tahun 2024/2025'));

      final jsonId = {'id': '1', 'text': 'Semester 1'};
      final item2 = NilaiOpsiItem.fromJson(jsonId);
      expect(item2.value, equals('1'));
      expect(item2.label, equals('Semester 1'));
    });

    test('handles empty json with empty defaults', () {
      final item = NilaiOpsiItem.fromJson({});
      expect(item.value, equals(''));
      expect(item.label, equals(''));
    });

    test('supports equality and hashCode', () {
      const itemA = NilaiOpsiItem(value: '2025', label: 'Tahun 2025');
      const itemB = NilaiOpsiItem(value: '2025', label: 'Tahun 2025');
      const itemC = NilaiOpsiItem(value: '2026', label: 'Tahun 2026');

      expect(itemA, equals(itemB));
      expect(itemA.hashCode, equals(itemB.hashCode));
      expect(itemA, isNot(equals(itemC)));
    });
  });

  group('RincianNilaiResponse.fromJson Tests', () {
    test('parses reguler, mbkm, kolom dinamis, and rentang nilai from full JSON', () {
      final payload = {
        'status': 'success',
        'message': 'Berhasil memuat rincian nilai',
        'thn_akademik': '2025/2026',
        'semester_id': '1',
        'semester_label': 'Semester Ganjil',
        'thn_aktif': '2025/2026',
        'data': [
          {
            'jenis': 'reguler',
            'kolom': [
              'Kehadiran',
              'Tugas 1',
              'Tugas 2',
              'Kuis',
              'UTS',
              'UAS',
              'Praktikum'
            ],
            'matkul': [
              {
                'kode': 'IF101',
                'nama': 'Pemrograman Berorientasi Objek',
                'nilai': {
                  'Kehadiran': 100,
                  'Tugas 1': 85,
                  'Tugas 2': 90,
                  'Kuis': 80,
                  'UTS': 88,
                  'UAS': 92,
                  'Praktikum': 95,
                },
                'nilai_akhir': '89.5',
                'nilai_huruf': 'A',
              },
              {
                'kode': 'IF102',
                'nama': 'Algoritma dan Struktur Data',
                'nilai': {
                  'Kehadiran': 95,
                  'Tugas 1': 75,
                  'Tugas 2': 80,
                  'Kuis': 70,
                  'UTS': 82,
                  'UAS': 85,
                  'Praktikum': 88,
                },
                'nilai_akhir': '81.2',
                'nilai_huruf': 'A',
              },
            ],
          },
          {
            'jenis': 'mbkm',
            'kolom': ['Konversi SKS', 'Nilai Mutu'],
            'matkul': [
              {
                'kode': 'MBKM01',
                'nama': 'Magang Industri Bersertifikat',
                'nilai': {
                  'Konversi SKS': 20,
                  'Nilai Mutu': 4.0,
                },
                'nilai_akhir': '100',
                'nilai_huruf': 'A',
              }
            ],
          },
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

      // Check kelompok count
      expect(response.kelompok.length, equals(2));

      // Reguler group check
      final reguler = response.kelompok.firstWhere((k) => k.jenis == 'reguler');
      expect(reguler.kolom.length, equals(7));
      expect(reguler.kolom, containsAllInOrder(['Kehadiran', 'Tugas 1', 'Tugas 2', 'Kuis', 'UTS', 'UAS', 'Praktikum']));
      expect(reguler.matkul.length, equals(2));
      expect(reguler.matkul[0].kode, equals('IF101'));
      expect(reguler.matkul[0].nama, equals('Pemrograman Berorientasi Objek'));
      expect(reguler.matkul[0].nilai['Kehadiran'], equals(100));
      expect(reguler.matkul[0].nilai['Praktikum'], equals(95));
      expect(reguler.matkul[0].nilaiAkhir, equals('89.5'));
      expect(reguler.matkul[0].nilaiHuruf, equals('A'));

      // MBKM group check
      final mbkm = response.kelompok.firstWhere((k) => k.jenis == 'mbkm');
      expect(mbkm.kolom, equals(['Konversi SKS', 'Nilai Mutu']));
      expect(mbkm.matkul.length, equals(1));
      expect(mbkm.matkul[0].kode, equals('MBKM01'));
      expect(mbkm.matkul[0].nilai['Konversi SKS'], equals(20));
      expect(mbkm.matkul[0].nilaiAkhir, equals('100'));
      expect(mbkm.matkul[0].nilaiHuruf, equals('A'));

      // Rentang Nilai check
      expect(response.rentangNilai.length, equals(5));
      expect(response.rentangNilai[0].rentang, equals('81 - 100'));
      expect(response.rentangNilai[0].huruf, equals('A'));
      expect(response.rentangNilai[0].bobot, equals('4.00'));
      expect(response.rentangNilai[4].rentang, equals('0 - 20'));
      expect(response.rentangNilai[4].huruf, equals('E'));
      expect(response.rentangNilai[4].bobot, equals('0.00'));
    });

    test('parses alternative Map structure for data and camelCase keys', () {
      final jsonMapData = {
        'thnAkademik': '2024/2025',
        'semesterId': '2',
        'semesterLabel': 'Genap',
        'thnAktif': '2024/2025',
        'data': {
          'reguler': {
            'kolom': ['Nilai 1', 'Nilai 2'],
            'matkul': [
              {
                'kdmk': 'CS201',
                'nmmk': 'Jaringan Komputer',
                'nilai': {'Nilai 1': 90, 'Nilai 2': 85},
                'na': '87.5',
                'nh': 'A',
              }
            ],
          },
          'mbkm': {
            'kolom': ['Nilai Magang'],
            'matkul': [
              {
                'kdmk': 'MB202',
                'nmmk': 'Bangkit Academy',
                'nilai': {'Nilai Magang': 95},
                'na': '95',
                'nh': 'A',
              }
            ],
          }
        },
        'rentangNilai': [
          {'rentang': '80 - 100', 'nilaiHuruf': 'A', 'bobot': '4.00'},
        ],
      };

      final response = RincianNilaiResponse.fromJson(jsonMapData);

      expect(response.thnAkademik, equals('2024/2025'));
      expect(response.semesterId, equals('2'));
      expect(response.semesterLabel, equals('Genap'));
      expect(response.kelompok.length, equals(2));

      final reguler = response.kelompok.firstWhere((k) => k.jenis == 'reguler');
      expect(reguler.matkul.first.kode, equals('CS201'));
      expect(reguler.matkul.first.nama, equals('Jaringan Komputer'));
      expect(reguler.matkul.first.nilaiAkhir, equals('87.5'));
      expect(reguler.matkul.first.nilaiHuruf, equals('A'));

      final mbkm = response.kelompok.firstWhere((k) => k.jenis == 'mbkm');
      expect(mbkm.matkul.first.kode, equals('MB202'));
      expect(mbkm.matkul.first.nama, equals('Bangkit Academy'));

      expect(response.rentangNilai.length, equals(1));
      expect(response.rentangNilai.first.huruf, equals('A'));
    });

    test('supports serialization toJson and roundtrip', () {
      final original = RincianNilaiResponse(
        thnAkademik: '2025/2026',
        semesterId: '1',
        semesterLabel: 'Ganjil',
        thnAktif: '2025/2026',
        kelompok: [
          const KelompokNilaiItem(
            jenis: 'reguler',
            kolom: ['Tugas', 'UAS'],
            matkul: [
              MatkulNilaiItem(
                kode: 'TEST01',
                nama: 'Testing Matkul',
                nilai: {'Tugas': 100, 'UAS': 90},
                nilaiAkhir: '95',
                nilaiHuruf: 'A',
              )
            ],
          )
        ],
        rentangNilai: [
          const RentangNilaiItem(rentang: '80-100', huruf: 'A', bobot: '4.0'),
        ],
      );

      final json = original.toJson();
      final reconstituted = RincianNilaiResponse.fromJson(json);

      expect(reconstituted.thnAkademik, equals(original.thnAkademik));
      expect(reconstituted.semesterId, equals(original.semesterId));
      expect(reconstituted.semesterLabel, equals(original.semesterLabel));
      expect(reconstituted.kelompok.length, equals(1));
      expect(reconstituted.kelompok.first.kolom, equals(['Tugas', 'UAS']));
      expect(reconstituted.kelompok.first.matkul.first.nama, equals('Testing Matkul'));
      expect(reconstituted.rentangNilai.first.huruf, equals('A'));
    });
  });

  group('Rate Limit (429) & Error Handling Tests (Fase 6)', () {
    test('ApiClient.handleError maps 429 to Indonesian error message', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          statusCode: 429,
          data: {'message': 'Too many requests'},
        ),
      );

      final err = ApiClient.handleError(dioError);
      expect(err.toString(), contains('Terlalu banyak permintaan. Silakan tunggu sebentar.'));
    });

    test('DioException with 429 correctly holds Retry-After header and data', () {
      final headers = Headers();
      headers.set('retry-after', '45');

      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          statusCode: 429,
          headers: headers,
          data: {'retry_after': 45, 'message': 'Rate limit exceeded'},
        ),
      );

      expect(dioError.response?.statusCode, equals(429));
      expect(dioError.response?.headers.value('retry-after'), equals('45'));
      expect(int.tryParse(dioError.response?.headers.value('retry-after') ?? ''), equals(45));
    });

    testWidgets('LoginPage renders form and login button properly', (tester) async {
      SharedPreferences.setMockInitialValues({'disclaimer_accepted_v1': true});
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.enabled, isTrue);
    });
  });
}
