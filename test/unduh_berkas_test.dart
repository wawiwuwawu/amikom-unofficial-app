// Kontrak nama berkas unduhan + fallback penyimpanan non-Android.
//
// Nama berkas kini membawa tanggal unduh + identitas (nama + NIM) supaya
// berkas lama/baru di folder Download ketahuan kapan diunduh dan milik siapa.
// Penyimpanan Android lewat MediaStore (DownloadStorageManager.kt); di host
// non-Android (test) simpanKeDownload jatuh ke dart:io biasa.

import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    // Fallback non-Android memakai getApplicationDocumentsDirectory() —
    // arahkan ke temp dir host supaya bisa diuji tanpa platform channel nyata.
    final tmp = await Directory.systemTemp.createTemp('unduh_uji');
    PathProviderPlatform.instance = _PathProviderPalsu(tmp.path);
  });

  setUp(() async {
    // identitas sesi baru per test: mock secure storage kosong = nim/nama null
    FlutterSecureStorage.setMockInitialValues({});
    await ApiClient.instance
        .setUserInfo('23SA21A060', 'Wawi')
        .then((_) => null)
        .catchError((_) {});
  });

  group('susunNamaBerkas', () {
    test('lengkap: jenis + tahun + semester + tanggal + identitas', () {
      final nama = ApiClient.susunNamaBerkas(
        jenis: 'KRS',
        tahun: '2026-2027',
        semester: 'SMT1',
        sekarang: DateTime(2026, 11, 12),
      );
      expect(nama, 'KRS 2026-2027 SMT1 12-11-2026 Wawi (23SA21A060).pdf');
    });

    test('tahun/semester kosong tidak menyisakan spasi ganda', () {
      final nama = ApiClient.susunNamaBerkas(
        jenis: 'Transkrip',
        sekarang: DateTime(2026, 11, 12),
      );
      expect(nama, 'Transkrip 12-11-2026 Wawi (23SA21A060).pdf');
    });

    test('tanpa nama sesi → identitas hanya NIM', () async {
      FlutterSecureStorage.setMockInitialValues({});
      await ApiClient.instance.setUserInfo('23SA21A060', '');
      final nama = ApiClient.susunNamaBerkas(
        jenis: 'KHS',
        sekarang: DateTime(2026, 11, 12),
      );
      expect(nama, 'KHS 12-11-2026 23SA21A060.pdf');
    });

    test('tanggal dua digit di-paddLeft (1 Januari bukan 1-1)', () {
      final nama = ApiClient.susunNamaBerkas(
        jenis: 'X',
        sekarang: DateTime(2026, 1, 3),
      );
      expect(nama, startsWith('X 03-01-2026'));
    });

    test('ext kustom dipertahankan', () {
      final nama = ApiClient.susunNamaBerkas(
        jenis: 'Panduan',
        ext: '.docx',
        sekarang: DateTime(2026, 11, 12),
      );
      expect(nama, endsWith('.docx'));
    });
  });

  group('beriKonteksUnduh', () {
    test('stem + tanggal + identitas, ext asli dipertahankan', () {
      final nama = ApiClient.beriKonteksUnduh(
        'sertifikat_12.pdf',
        sekarang: DateTime(2026, 11, 12),
      );
      expect(nama, 'sertifikat_12 12-11-2026 Wawi (23SA21A060).pdf');
    });

    test('nama tanpa titik → tanpa ext', () {
      final nama = ApiClient.beriKonteksUnduh(
        'bukti',
        sekarang: DateTime(2026, 11, 12),
      );
      expect(nama, 'bukti 12-11-2026 Wawi (23SA21A060)');
    });

    test('titik di tengah nama (folder url) tidak dianggap ext', () {
      final nama = ApiClient.beriKonteksUnduh(
        'panduan.v2.pdf',
        sekarang: DateTime(2026, 11, 12),
      );
      expect(nama, 'panduan.v2 12-11-2026 Wawi (23SA21A060).pdf');
    });
  });

  group('simpanKeDownload — fallback non-Android (host test)', () {
    test('menulis bytes ke berkas dan mengembalikan path', () async {
      final bytes = <int>[1, 2, 3, 4, 5];
      final path = await ApiClient.simpanKeDownload('uji_simpan.pdf', bytes);
      final file = File(path);
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), bytes);
    });
  });
}

class _PathProviderPalsu extends PathProviderPlatform {
  _PathProviderPalsu(this._docsPath);
  final String _docsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => _docsPath;
}
