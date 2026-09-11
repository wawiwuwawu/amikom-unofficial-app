import 'package:flutter_test/flutter_test.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/models/krs.dart';
import 'package:app_amikom/models/asisten.dart';
import 'package:app_amikom/models/berita.dart';

void main() {
  group('Fase 3 Service contracts & models', () {
    test('Krs models parse unwrapRoot correctly', () {
      final krsInfoPayload = {
        'status': 'success',
        'data': null,
        'periode_pengajuan': {
          'tanggal_mulai': '05 Februari 2026',
          'tanggal_selesai': '14 Februari 2026',
          'teks_mentah': 'Pengajuan dibuka',
        },
        'periode_pengisian': {
          'tanggal_mulai': '23 Februari 2026',
          'tanggal_selesai': '23 Februari 2026',
          'teks_mentah': 'Pengisian dibuka',
        },
        'tagihan': {
          'download_url': '/download/pdf',
          'tahun_akademik': '2025/2026',
          'semester': '2',
        },
      };

      final rootInfo = ApiClient.unwrapRoot(krsInfoPayload);
      final info = KrsInfo.fromJson(rootInfo);
      expect(info.periodePengajuan?.tanggalMulai, equals('05 Februari 2026'));
      expect(info.periodePengisian?.tanggalMulai, equals('23 Februari 2026'));
      expect(info.tagihan?.tahunAkademik, equals('2025/2026'));

      final matkulDitawarkanPayload = {
        'status': 'success',
        'data': [
          {
            'semester': 8,
            'kode': 'USSIW057',
            'nama': 'Skripsi',
            'sks': 6,
            'status': 'baru',
            'is_ulang': false,
            'nilai_sebelumnya': null,
            'raw_value': '6_2120082_USSIW057 _A ',
          }
        ],
        'max_sks': 24,
        'sks_saat_ini': 6,
      };

      final rootMatkul = ApiClient.unwrapRoot(matkulDitawarkanPayload);
      final matkulRes = MatkulDitawarkanResponse.fromJson(rootMatkul);
      expect(matkulRes.maxSks, equals(24));
      expect(matkulRes.sksSaatIni, equals(6));
      expect(matkulRes.data.length, equals(1));
      expect(matkulRes.data.first.nama, equals('Skripsi'));
    });

    test('Asisten models parse unwrapData and unwrapRoot', () {
      final asistenInfoPayload = {
        'status': 'success',
        'data': {
          'mahasiswa': {
            'npm': '21.11.0001',
            'NAMA': 'Mahasiswa Test',
            'koda': 'AST',
            'nama_dept': 'IF',
            'pa': 'Dosen PA',
          },
          'stats': {
            'hadir': 10,
            'izin': 0,
            'pengganti': 0,
            'alpa': 0,
            'rataRataMhs': 90.0,
          },
          'aturan': {
            'total_presensi': 14,
            'rata_rata': 80.0,
          },
          'bisaAjukanBebasKP': true,
        }
      };

      final asistenData = ApiClient.unwrapData<Map<String, dynamic>>(asistenInfoPayload);
      final asistenInfo = AsistenInfo.fromJson(asistenData);
      expect(asistenInfo.mahasiswa.npm, equals('21.11.0001'));
      expect(asistenInfo.stats.hadir, equals(10));
      expect(asistenInfo.bisaAjukanBebasKP, isTrue);

      final laporanPayload = {
        'status': 'success',
        'data': {
          'labels': ['2024/2025 - Ganjil'],
          'datasets': [
            {
              'type': 'line',
              'label': 'Kehadiran Asisten',
              'borderColor': '#e66235',
              'data': [95.0],
            }
          ]
        }
      };

      final rootLaporan = ApiClient.unwrapRoot(laporanPayload);
      final laporan = AsistenLaporan.fromJson(rootLaporan);
      expect(laporan.labels, contains('2024/2025 - Ganjil'));
      expect(laporan.datasets.first.data.first, equals(95.0));
    });

    test('Pagination model parses nullable nextOffset correctly', () {
      final p1 = Pagination.fromJson({
        'currentPage': 1,
        'nextOffset': 5,
        'prevOffset': null,
      });
      expect(p1.currentPage, equals(1));
      expect(p1.nextOffset, equals(5));
      expect(p1.hasMore, isTrue);

      final p2 = Pagination.fromJson({
        'currentPage': 2,
        'nextOffset': null,
        'prevOffset': 0,
      });
      expect(p2.currentPage, equals(2));
      expect(p2.nextOffset, isNull);
      expect(p2.hasMore, isFalse);
    });

    test('unwrapMutation catches success: false in envelope', () {
      final payload = {
        'status': 'success',
        'data': null,
        'success': false,
        'message': 'Gagal validasi di portal',
      };

      expect(
        () => ApiClient.unwrapMutation(payload),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('Gagal validasi di portal'))),
      );
    });
  });
}
