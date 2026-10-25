// Test AgendaCacheService: roundtrip simpan→baca, fail-open (JSON rusak →
// null), timestamp "data terakhir", dan pembersihan saat logout (kunci
// ber-suffix NIM maupun tanpa suffix). Pola SharedPreferences.setMockInitialValues
// seperti test/pengingat_jadwal_service_test.dart.

import 'package:app_amikom/models/agenda_terpadu.dart';
import 'package:app_amikom/services/agenda_cache_service.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCache = 'agenda_terpadu_cache';
const _kCacheAt = 'agenda_terpadu_cache_at';
const _nim = '2200001';
const _suffix = '_$_nim';

AgendaTerpaduData _agenda() => AgendaTerpaduData.fromJson({
  'total_agenda': 2,
  'agenda': {
    'Senin': [
      {
        'tipe': 'kuliah',
        'hari': 'Senin',
        'jam': '09:00 - 10:40',
        'jam_mulai': '09:00',
        'jam_selesai': '10:40',
        'ruang': 'LT2',
        'matakuliah': 'Pemrograman Mobile',
        'detail': 'Dosen: Budi',
        'komponen': 'teori',
      },
      {
        'tipe': 'uas',
        'hari': 'HariIni',
        'jam': '08:00 - 10:00',
        'ruang': 'AULA',
        'matakuliah': 'Ujian Akhir Semester',
        'detail': '',
        'tanggal': '2026-11-05',
      },
    ],
  },
});

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Identitas NIM ditetapkan sekali — suffix kunci cache mengikutinya.
    // Penulisan secure storage best-effort; di test di-swallow oleh service.
    ApiClient.instance.setUserInfo(_nim, 'Budi Santoso');
  });

  group('simpan → baca roundtrip', () {
    test('mempertahankan seluruh field termasuk komponen dan tanggal ujian',
        () async {
      final sumber = _agenda();
      await AgendaCacheService.instance.simpan(sumber);

      final hasil = await AgendaCacheService.instance.baca();

      expect(hasil, isNotNull);
      expect(hasil!.totalAgenda, 2);
      final senin = hasil.agenda['Senin'];
      expect(senin, isNotNull);
      expect(senin!.length, 2);

      final kuliah = senin[0];
      expect(kuliah.tipe, 'kuliah');
      expect(kuliah.jam, '09:00 - 10:40');
      expect(kuliah.jamMulai, '09:00');
      expect(kuliah.jamSelesai, '10:40');
      expect(kuliah.ruang, 'LT2');
      expect(kuliah.matakuliah, 'Pemrograman Mobile');
      expect(kuliah.detail, 'Dosen: Budi');
      expect(kuliah.komponen, 'teori');

      // Field `tanggal` ujian wajib selamat — gerbang tampil ujian Dashboard
      // membaca field ini dari data cache.
      final ujian = senin[1];
      expect(ujian.tipe, 'uas');
      expect(ujian.tanggal, '2026-11-05');
    });

    test('simpan ulang menimpa isi lama', () async {
      await AgendaCacheService.instance.simpan(
        AgendaTerpaduData.fromJson({
          'total_agenda': 1,
          'agenda': {
            'Selasa': [
              {
                'tipe': 'kuliah',
                'hari': 'Selasa',
                'jam': '08:00 - 09:40',
                'ruang': 'D.3.A',
                'matakuliah': 'Lama',
                'detail': '',
              },
            ],
          },
        }),
      );
      await AgendaCacheService.instance.simpan(_agenda());

      final hasil = await AgendaCacheService.instance.baca();
      expect(hasil!.agenda.containsKey('Selasa'), isFalse);
      expect(hasil.agenda.containsKey('Senin'), isTrue);
    });
  });

  group('baca — fail-open', () {
    test('cache kosong → null', () async {
      expect(await AgendaCacheService.instance.baca(), isNull);
    });

    test('JSON rusak → null, tidak melempar', () async {
      SharedPreferences.setMockInitialValues({
        '$_kCache$_suffix': '{bukan json valid',
      });
      expect(await AgendaCacheService.instance.baca(), isNull);
    });

    test('JSON bukan objek (array) → null', () async {
      SharedPreferences.setMockInitialValues({
        '$_kCache$_suffix': '["bukan","objek"]',
      });
      expect(await AgendaCacheService.instance.baca(), isNull);
    });
  });

  group('terakhirDisimpan', () {
    test('belum pernah simpan → null', () async {
      expect(await AgendaCacheService.instance.terakhirDisimpan(), isNull);
    });

    test('setelah simpan → mendekati waktu sekarang', () async {
      final sebelum = DateTime.now();
      await AgendaCacheService.instance.simpan(_agenda());
      final terakhir = await AgendaCacheService.instance.terakhirDisimpan();

      expect(terakhir, isNotNull);
      final beda = terakhir!.difference(sebelum).inMilliseconds.abs();
      expect(beda, lessThan(5000), reason: 'timestamp = waktu simpan');
    });
  });

  group('bersihkanSaatLogout', () {
    test('menghapus kunci ber-suffix NIM dan kunci tanpa suffix', () async {
      SharedPreferences.setMockInitialValues({
        '$_kCache$_suffix': '{}',
        '$_kCacheAt$_suffix': 1700000000000,
        _kCache: '{}',
        '${_kCacheAt}_': 1, // beda kunci — TIDAK boleh ikut terhapus
      });

      await AgendaCacheService.instance.bersihkanSaatLogout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('$_kCache$_suffix'), isNull);
      expect(prefs.getInt('$_kCacheAt$_suffix'), isNull);
      expect(prefs.getString(_kCache), isNull);
      // Kunci milik entitas lain tidak tersentuh.
      expect(prefs.getInt('${_kCacheAt}_'), 1);
    });

    test('idempoten — dipanggil ulang tanpa error', () async {
      await AgendaCacheService.instance.bersihkanSaatLogout();
      await AgendaCacheService.instance.bersihkanSaatLogout();
      expect(await AgendaCacheService.instance.baca(), isNull);
    });
  });
}
