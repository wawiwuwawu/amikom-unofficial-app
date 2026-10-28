// Test WidgetJadwalService (versi peta-mingguan): Dart menulis SATU kunci
// `jadwal_json` — peta baris per kunci nama hari + tanggal ISO ujian — dan
// provider native memilih baris tanggal perangkat tiap render (perbaikan bug:
// versi pertama membekukan baris di hari terakhir app dibuka). Yang diuji di
// sini sisi Dart: petaMingguan/barisHariIni (pure), isi JSON yang ditulis via
// [WidgetJadwalGateway] palsu, fail-open, dan pembersihan logout (null =
// kunci dihapus). TIDAK menyentuh plugin home_widget.

import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:app_amikom/models/agenda_terpadu.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/widget_jadwal_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _GatewayPalsu implements WidgetJadwalGateway {
  final data = <String, String?>{};
  int jumlahPerbaruiWidget = 0;

  @override
  Future<void> simpanData(String kunci, String? nilai) async {
    // Native: saveWidgetData(nil) menghapus entri (HomeWidgetPlugin.remove).
    if (nilai == null) {
      data.remove(kunci);
    } else {
      data[kunci] = nilai;
    }
  }

  @override
  Future<void> perbaruiWidget() async {
    jumlahPerbaruiWidget++;
  }
}

AgendaTerpaduData _agendaDenganHari(String hari, [List<Map<String, dynamic>>? baris]) =>
    AgendaTerpaduData.fromJson({
      'total_agenda': baris?.length ?? 0,
      'agenda': {
        hari: baris ?? const [],
      },
    });

Map<String, dynamic> _matkul(
  String nama,
  String jamMulai, {
  String ruang = 'LT2',
  String hari = 'Senin',
  String? tanggal,
}) => {
  'tipe': tanggal != null ? 'uas' : 'kuliah',
  'hari': hari,
  'jam': '$jamMulai - 10:40',
  'jam_mulai': jamMulai,
  'jam_selesai': '10:40',
  'ruang': ruang,
  'matakuliah': nama,
  'detail': '',
  'tanggal': ?tanggal,
};

Map<String, List<dynamic>> _peta(String? json) =>
    json == null ? {} : Map<String, List<dynamic>>.from(jsonDecode(json) as Map);

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Identitas NIM menentukan suffix kunci cache yang dibaca service.
    ApiClient.instance.setUserInfo('2200001', 'Budi Santoso');
  });

  group('petaMingguan (pure)', () {
    test('tiap hari jadi kunci sendiri; terurut jam; tanpa jam di akhir', () {
      final agenda = AgendaTerpaduData.fromJson({
        'total_agenda': 4,
        'agenda': {
          'Senin': [
            _matkul('Basis Data', '10:00', hari: 'Senin'),
            _matkul('Pemrograman Web', '07:30', hari: 'Senin'),
            {
              'tipe': 'skripsi',
              'hari': 'Senin',
              'jam': '-',
              'ruang': '',
              'matakuliah': 'Bimbingan (belum berjam)',
              'detail': '',
            },
          ],
          'Selasa': [_matkul('Jaringan', '09:00', hari: 'Selasa')],
        },
      });

      final peta = WidgetJadwalService.petaMingguan(agenda);

      expect(peta.keys.length, 2);
      expect(peta['Senin'], [
        '07:30 · Pemrograman Web · LT2',
        '10:00 · Basis Data · LT2',
        // Tanpa jam di akhir, tanpa suffix ruang kosong.
        '- · Bimbingan (belum berjam)',
      ]);
      expect(peta['Selasa'], ['09:00 · Jaringan · LT2']);
    });

    test('ujian ber-tanggal pindah ke kunci tanggal ISO (bukan nama hari)', () {
      final agenda = _agendaDenganHari('HariIni', [
        _matkul('UAS Pemrograman Mobile', '08:00',
            hari: 'HariIni', tanggal: '2026-11-05'),
      ]);

      final peta = WidgetJadwalService.petaMingguan(agenda);

      expect(peta.containsKey('HariIni'), isFalse);
      expect(peta['2026-11-05'], ['08:00 · UAS Pemrograman Mobile · LT2']);
    });

    test('ujian tanpa tanggal (BE lama) tetap di bucket nama hari — fail-open',
        () {
      final agenda = AgendaTerpaduData.fromJson({
        'total_agenda': 1,
        'agenda': {
          'HariIni': [
            {
              'tipe': 'uts',
              'hari': 'HariIni',
              'jam': '08:00 - 10:00',
              'jam_mulai': '08:00',
              'jam_selesai': '10:00',
              'ruang': 'AULA',
              'matakuliah': 'UTS Lama',
              'detail': '',
            },
          ],
        },
      });

      expect(WidgetJadwalService.petaMingguan(agenda)['HariIni'],
          ['08:00 · UTS Lama · AULA']);
    });

    test('data null → peta kosong', () {
      expect(WidgetJadwalService.petaMingguan(null), isEmpty);
    });

    test('kunci HANYA berisi baris tanpa jam (mis. "Tanpa Jadwal") tidak '
        'melempar UnsupportedError — regresi bug nyata 2026-10-29', () {
      // Bug nyata: `const []..sort()` pada kunci tanpa entri berjam
      // menggagalkan SELURUH penulisan widget.
      final agenda = AgendaTerpaduData.fromJson({
        'total_agenda': 2,
        'agenda': {
          'Senin': [_matkul('Berjam', '07:30', hari: 'Senin')],
          'Tanpa Jadwal': [
            {
              'tipe': 'kuliah',
              'hari': 'Tanpa Jadwal',
              'jam': '-',
              'jam_mulai': '',
              'jam_selesai': '',
              'ruang': '',
              'matakuliah': 'Skripsi',
              'detail': 'Tanpa kelas',
              'komponen': 'teori',
            },
          ],
        },
      });

      final peta = WidgetJadwalService.petaMingguan(agenda);

      expect(peta['Senin'], ['07:30 · Berjam · LT2']);
      expect(peta['Tanpa Jadwal'], ['- · Skripsi']);
    });
  });

  group('barisHariIni (referensi perilaku native)', () {
    final senin = DateTime(2026, 10, 26); // Senin

    test('gabungan kelas (kunci hari) + ujian (kunci tanggal), maks 4', () {
      final agenda = _agendaDenganHari('Senin', [
        _matkul('A', '07:00'),
        _matkul('B', '08:00'),
        _matkul('C', '09:00'),
      ]);

      // Ujian pada tanggal yang sama — masuk lewat kunci ISO.
      final peta = WidgetJadwalService.petaMingguan(agenda);
      peta['2026-10-26'] = ['13:00 · UAS A · AULA'];
      final baris = [
        ...(peta['Senin'] ?? const []),
        ...(peta['2026-10-26'] ?? const []),
      ].take(4);

      // barisHariIni sendiri menghitung dari data; uji wrapper-nya dengan
      // agenda yang punya kedua kunci sekaligus.
      final agendaLengkap = AgendaTerpaduData.fromJson({
        'total_agenda': 4,
        'agenda': {
          'Senin': [
            _matkul('A', '07:00'),
            _matkul('B', '08:00'),
            _matkul('C', '09:00'),
          ],
          'HariIni': [
            _matkul('UAS A', '13:00', hari: 'HariIni', tanggal: '2026-10-26'),
          ],
        },
      });

      expect(baris.length, 4);
      expect(
        WidgetJadwalService.barisHariIni(agendaLengkap, senin),
        [
          '07:00 · A · LT2',
          '08:00 · B · LT2',
          '09:00 · C · LT2',
          '13:00 · UAS A · LT2',
        ],
      );
    });

    test('maksimal 4 baris per kunci hari', () {
      final agenda = _agendaDenganHari('Senin', [
        for (var i = 0; i < 6; i++) _matkul('MK$i', '0${i + 7}:00'),
      ]);
      expect(WidgetJadwalService.barisHariIni(agenda, senin).length, 4);
    });

    test('hari tidak cocok → kosong; data null → kosong', () {
      final agenda = _agendaDenganHari('Selasa', [_matkul('X', '07:30')]);
      expect(WidgetJadwalService.barisHariIni(agenda, senin), isEmpty);
      expect(WidgetJadwalService.barisHariIni(null, senin), isEmpty);
    });
  });

  group('terapkan (via gateway palsu)', () {
    test('menulis jadwal_json berisi kunci hari + tanggal, lalu update', () async {
      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);

      await service.terapkan(
        data: AgendaTerpaduData.fromJson({
          'total_agenda': 2,
          'agenda': {
            'Senin': [_matkul('Pemrograman Web', '07:30', hari: 'Senin')],
            'HariIni': [
              _matkul('UAS A', '13:00',
                  hari: 'HariIni', tanggal: '2026-11-05'),
            ],
          },
        }),
      );

      final peta = _peta(gateway.data['jadwal_json']);
      expect(peta['Senin'], ['07:30 · Pemrograman Web · LT2']);
      expect(peta['2026-11-05'], ['13:00 · UAS A · LT2']);
      expect(gateway.jumlahPerbaruiWidget, 1);
    });

    test('data null → kunci jadwal_json DIHAPUS (native → tanpa_data)',
        () async {
      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);
      gateway.data['jadwal_json'] = '{"Senin": ["07:30 · Lama · LT2"]}';

      await service.terapkan(data: null);

      expect(gateway.data.containsKey('jadwal_json'), isFalse);
      expect(gateway.jumlahPerbaruiWidget, 1);
    });
  });

  group('perbaruiDariData (jalur anti-race)', () {
    test('data langsung diterapkan walau cache MASIH KOSONG', () async {
      // Skenario bug nyata: pemanggil baru fetch sukses dan menulis cache
      // unawaited; baca cache bisa mendahului tulisan → widget dapat null.
      // perbaruiDariData memotong jalur cache sama sekali.
      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);

      await service.perbaruiDariData(_agendaDenganHari('Senin', [
        _matkul('Pemrograman Web', '07:30', hari: 'Senin'),
      ]));

      final peta = _peta(gateway.data['jadwal_json']);
      expect(peta['Senin'], ['07:30 · Pemrograman Web · LT2']);
      expect(gateway.jumlahPerbaruiWidget, 1);
    });

    test('data tidak menimpa sesi cache lain — menimpa jadwal_json lama', () async {
      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);
      gateway.data['jadwal_json'] = '{"Minggu": ["lama"]}';

      await service.perbaruiDariData(_agendaDenganHari('Senin', [
        _matkul('Baru', '08:00', hari: 'Senin'),
      ]));

      final peta = _peta(gateway.data['jadwal_json']);
      expect(peta.containsKey('Minggu'), isFalse);
      expect(peta['Senin'], ['08:00 · Baru · LT2']);
    });
  });

  group('perbaruiDariCache (fail-open)', () {
    test('cache berisi agenda → jadwal_json terisi', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('agenda_terpadu_cache_2200001', jsonEncode({
        'total_agenda': 1,
        'agenda': {
          'Senin': [_matkul('Pemrograman Web', '09:00', hari: 'Senin')],
        },
      }));

      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);

      await service.perbaruiDariCache();

      final peta = _peta(gateway.data['jadwal_json']);
      expect(peta['Senin'], ['09:00 · Pemrograman Web · LT2']);
    });

    test('cache kosong/rusak → kunci dihapus, tanpa melempar', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('agenda_terpadu_cache_2200001', '{json-rusak');

      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);
      gateway.data['jadwal_json'] = '{"Senin": ["lama"]}';

      await service.perbaruiDariCache();

      expect(gateway.data.containsKey('jadwal_json'), isFalse);
      expect(gateway.jumlahPerbaruiWidget, 1);
    });
  });

  group('bersihkanSaatLogout', () {
    test('menghapus kunci jadwal_json (native → tanpa_data)', () async {
      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);
      gateway.data['jadwal_json'] = '{"Senin": ["07:30 · Lama · LT2"]}';

      await service.bersihkanSaatLogout();

      expect(gateway.data.containsKey('jadwal_json'), isFalse);
      expect(gateway.jumlahPerbaruiWidget, 1);
    });
  });

  tearDown(() {
    // Kembalikan gateway asli supaya test lain tidak memakai gateway palsu.
    WidgetJadwalService.instance.gantiGatewayUntukTest(HomeWidgetGateway());
  });
}
