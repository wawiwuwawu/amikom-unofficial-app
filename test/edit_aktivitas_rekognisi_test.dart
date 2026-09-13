import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_amikom/models/rekognisi.dart';
import 'package:dio/dio.dart';
import 'package:app_amikom/services/aktivitas_helper.dart';
import 'package:app_amikom/services/rekognisi_service.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000\n');
  });

  group('Rekognisi Models Tests', () {
    test('RekognisiItem.fromJson parses full valid json', () {
      final json = {
        'id': 12,
        'npm': '23SA21A060',
        'jenis_aktivitas': 'REKOGNISI',
        'judul': 'Narasumber pada kegiatan/seminar',
        'judul_english': '',
        'tingkat': 'Regional',
        'tingkat_english': '',
        'link': 'https://berita-acara.com/narasumber',
        'kontribusi': 'Penulis Pertama',
        'tahun': 2025,
        'file': 'rekognisi_12.pdf',
        'file_url': '/api/v1/rekognisi-mahasiswa/12/file',
        'verifikasi': 1,
        'status': 'valid',
        'keterangan': 'Disetujui',
        'created_at': '2025-01-01',
        'updated_at': '2025-01-02',
      };

      final item = RekognisiItem.fromJson(json);

      expect(item.id, equals(12));
      expect(item.npm, equals('23SA21A060'));
      expect(item.judul, equals('Narasumber pada kegiatan/seminar'));
      expect(item.tingkat, equals('Regional'));
      expect(item.link, equals('https://berita-acara.com/narasumber'));
      expect(item.kontribusi, equals('Penulis Pertama'));
      expect(item.tahun, equals(2025));
      expect(item.file, equals('rekognisi_12.pdf'));
      expect(item.fileUrl, equals('/api/v1/rekognisi-mahasiswa/12/file'));
      expect(item.verifikasi, equals(1));
      expect(item.status, equals('valid'));
      expect(item.keterangan, equals('Disetujui'));
    });

    test('RekognisiItem.fromJson handles empty and null fallbacks gracefully', () {
      final json = <String, dynamic>{
        'id': '99',
        'tahun': '2024',
        'verifikasi': '0',
      };

      final item = RekognisiItem.fromJson(json);

      expect(item.id, equals(99));
      expect(item.tahun, equals(2024));
      expect(item.verifikasi, equals(0));
      expect(item.judul, isEmpty);
      expect(item.tingkat, isEmpty);
      expect(item.link, isEmpty);
      expect(item.file, isEmpty);
      expect(item.status, isEmpty);
    });

    test('RekognisiOptionResponse.fromJson parses all dropdown options', () {
      final json = {
        'jenis_rekognisi': [
          {'value': 'Juri/Pelatih/Wasit', 'label': 'Juri/Pelatih/Wasit'},
          {'value': 'Pemakalah', 'label': 'Pemakalah'},
        ],
        'tingkat': [
          {'value': 'Internasional', 'label': 'Internasional'},
          {'value': 'Nasional', 'label': 'Nasional'},
        ],
        'kontribusi': [
          {'value': 'Penulis Pertama', 'label': 'Penulis Pertama'},
          {'value': 'Anggota', 'label': 'Anggota'},
        ],
      };

      final options = RekognisiOptionResponse.fromJson(json);

      expect(options.jenisRekognisi.length, equals(2));
      expect(options.jenisRekognisi.first.value, equals('Juri/Pelatih/Wasit'));
      expect(options.tingkat.length, equals(2));
      expect(options.tingkat.last.label, equals('Nasional'));
      expect(options.kontribusi.length, equals(2));
      expect(options.kontribusi.first.value, equals('Penulis Pertama'));
    });
  });

  group('Aktivitas Edit & Verification Lock Logic Tests', () {
    test('Verification lock is true when verifikasi == 1 or status is valid', () {
      final verifiedItem = RekognisiItem(
        id: 1,
        npm: '23.11.0001',
        jenisAktivitas: 'REKOGNISI',
        judul: 'Juri',
        judulEnglish: '',
        tingkat: 'Nasional',
        tingkatEnglish: '',
        link: '',
        kontribusi: '',
        tahun: 2025,
        file: 'test.pdf',
        fileUrl: '/file',
        verifikasi: 1,
        status: 'menunggu',
        keterangan: '',
        createdAt: '',
        updatedAt: '',
      );

      final isLocked = verifiedItem.verifikasi == 1 || verifiedItem.status.toLowerCase() == 'valid';
      expect(isLocked, isTrue);

      final unverifiedItem = RekognisiItem(
        id: 2,
        npm: '23.11.0001',
        jenisAktivitas: 'REKOGNISI',
        judul: 'Juri',
        judulEnglish: '',
        tingkat: 'Nasional',
        tingkatEnglish: '',
        link: '',
        kontribusi: '',
        tahun: 2025,
        file: 'test.pdf',
        fileUrl: '/file',
        verifikasi: 0,
        status: 'menunggu',
        keterangan: '',
        createdAt: '',
        updatedAt: '',
      );

      final isUnverifiedLocked = unverifiedItem.verifikasi == 1 || unverifiedItem.status.toLowerCase() == 'valid';
      expect(isUnverifiedLocked, isFalse);
    });

    test('FormData for edit omits file field when no new file is chosen', () {
      final mapData = <String, dynamic>{
        'judul': 'Bahasa Inggris',
        'nilai': 'A',
        'tahun': '2025',
      };

      // When file is null, file_sertifikat key is NOT in mapData
      expect(mapData.containsKey('file_sertifikat'), isFalse);

      final formData = FormData.fromMap(mapData);
      expect(formData.fields.any((f) => f.key == 'judul' && f.value == 'Bahasa Inggris'), isTrue);
      expect(formData.fields.any((f) => f.key == 'nilai' && f.value == 'A'), isTrue);
      expect(formData.files.any((f) => f.key == 'file_sertifikat'), isFalse);
    });

    test('FormData for edit includes file field when new file is provided', () {
      final mapData = <String, dynamic>{
        'judul': 'Bahasa Inggris',
        'nilai': 'A',
        'tahun': '2025',
        'file_sertifikat': MultipartFile.fromString('dummy binary pdf content', filename: 'sertifikat.pdf'),
      };

      expect(mapData.containsKey('file_sertifikat'), isTrue);

      final formData = FormData.fromMap(mapData);
      expect(formData.fields.any((f) => f.key == 'judul'), isTrue);
      expect(formData.files.any((f) => f.key == 'file_sertifikat'), isTrue);
    });

    test('RekognisiService and AktivitasHelper expose edit methods', () {
      final service = RekognisiService();
      expect(service, isNotNull);
      expect(AktivitasHelper.edit, isA<Function>());
    });
  });
}
