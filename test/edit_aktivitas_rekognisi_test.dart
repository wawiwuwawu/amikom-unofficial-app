import 'package:flutter_test/flutter_test.dart';
import 'package:app_amikom/models/rekognisi.dart';
import 'package:app_amikom/widgets/app_kit.dart';

void main() {
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
      expect(options.kontribusi.first.label, equals('Penulis Pertama'));
    });
  });

  group('Kunci verifikasi aktivitas', () {
    test('verifikasi == 1 → terkunci walau status masih menunggu', () {
      expect(isAktivitasTerkunci(1, 'menunggu'), isTrue);
    });

    test("status 'Valid' campuran huruf → terkunci walau verifikasi 0", () {
      expect(isAktivitasTerkunci(0, 'Valid'), isTrue);
    });

    test('verifikasi 0 + status menunggu → belum terkunci', () {
      expect(isAktivitasTerkunci(0, 'menunggu'), isFalse);
    });

    test('verifikasi 2 (ditolak) + status ditolak → tidak terkunci', () {
      expect(isAktivitasTerkunci(2, 'ditolak'), isFalse);
    });
  });
}
