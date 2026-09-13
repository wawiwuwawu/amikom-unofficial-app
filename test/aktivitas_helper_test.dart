import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_amikom/services/aktivitas_helper.dart';
import 'package:app_amikom/services/sertifikasi_service.dart';
import 'package:app_amikom/services/organisasi_service.dart';
import 'package:app_amikom/services/prestasi_service.dart';
import 'package:app_amikom/services/seminar_workshop_service.dart';

import 'package:app_amikom/models/rekognisi.dart';
import 'package:app_amikom/services/rekognisi_service.dart';
import 'package:dio/dio.dart';
void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000\n');
  });

  group('AktivitasHelper and SKPI Services contracts', () {
    test('Services can be instantiated', () {
      final sertifikasi = SertifikasiService();
      final organisasi = OrganisasiService();
      final prestasi = PrestasiService();
      final seminarWorkshop = SeminarWorkshopService();
      final rekognisi = RekognisiService();

      expect(sertifikasi, isNotNull);
      expect(organisasi, isNotNull);
      expect(prestasi, isNotNull);
      expect(seminarWorkshop, isNotNull);
      expect(rekognisi, isNotNull);
    });

    test('AktivitasHelper methods are declared with correct signatures', () {
      expect(AktivitasHelper.submit, isA<Function>());
      expect(AktivitasHelper.edit, isA<Function>());
      expect(AktivitasHelper.delete, isA<Function>());
      expect(AktivitasHelper.download, isA<Function>());
      expect(AktivitasHelper.downloadFile, isA<Function>());
    });

    test('AktivitasHelper wraps exceptions with fallback message', () async {
      // Calling delete with an invalid ID against non-running backend should throw handled Exception
      expect(
        () => AktivitasHelper.delete('/api/v1/invalid-path', 999999, 'Fallback Error Message'),
        throwsA(isA<Exception>()),
      );
    });

    test('AktivitasHelper edit wraps exceptions with fallback message', () async {
      expect(
        () => AktivitasHelper.edit('/api/v1/invalid-path', 999999, FormData(), 'Fallback Edit Error'),
        throwsA(isA<Exception>()),
      );
    });

    test('SKPI Services edit methods are declared', () {
      final sertifikasi = SertifikasiService();
      final organisasi = OrganisasiService();
      final prestasi = PrestasiService();
      final seminarWorkshop = SeminarWorkshopService();
      final rekognisi = RekognisiService();

      expect(sertifikasi.editSertifikasi, isA<Function>());
      expect(organisasi.editOrganisasi, isA<Function>());
      expect(prestasi.editPrestasi, isA<Function>());
      expect(seminarWorkshop.editSeminarWorkshop, isA<Function>());
      expect(rekognisi.editRekognisi, isA<Function>());
    });

    test('Rekognisi models parse JSON correctly', () {
      final sampleItemJson = {
        'id': 12,
        'npm': '23SA21A060',
        'jenis_aktivitas': 'REKOGNISI',
        'judul': 'Narasumber pada kegiatan/seminar',
        'judul_english': '',
        'tingkat': 'Regional',
        'tingkat_english': '',
        'link': 'https://berita-acara.com/narasumber',
        'kontribusi': null,
        'tahun': 2025,
        'file': 'rekognisi_12.pdf',
        'file_url': '/api/v1/rekognisi-mahasiswa/12/file',
        'verifikasi': 0,
        'status': 'menunggu',
        'keterangan': null,
        'created_at': null,
        'updated_at': null,
      };

      final item = RekognisiItem.fromJson(sampleItemJson);
      expect(item.id, 12);
      expect(item.npm, '23SA21A060');
      expect(item.judul, 'Narasumber pada kegiatan/seminar');
      expect(item.tingkat, 'Regional');
      expect(item.tahun, 2025);
      expect(item.verifikasi, 0);
      expect(item.status, 'menunggu');
      expect(item.kontribusi, '');
      expect(item.keterangan, '');

      final sampleOptionsJson = {
        'jenis_rekognisi': [
          {'value': 'Juri', 'label': 'Juri'}
        ],
        'tingkat': [
          {'value': 'Nasional', 'label': 'Nasional'}
        ],
        'kontribusi': [
          {'value': 'Penulis Pertama', 'label': 'Penulis Pertama'}
        ],
      };

      final options = RekognisiOptionResponse.fromJson(sampleOptionsJson);
      expect(options.jenisRekognisi.length, 1);
      expect(options.jenisRekognisi.first.value, 'Juri');
      expect(options.tingkat.length, 1);
      expect(options.tingkat.first.label, 'Nasional');
      expect(options.kontribusi.length, 1);
      expect(options.kontribusi.first.value, 'Penulis Pertama');
    });
  });
}
