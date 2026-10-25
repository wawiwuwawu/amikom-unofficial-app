// Test WidgetJadwalService: ekstraksi baris hari ini (sort jam, maks 4,
// tanpa jam di akhir, format jam · matkul · ruang), keadaan widget
// (ada/kosong/tanpa_data), judul tanggal Indonesia, fail-open (cache kosong
// tidak melempar), dan pembersihan logout. Seluruh penyimpanan lewat
// [WidgetJadwalGateway] palsu — TIDAK menyentuh plugin home_widget.

import 'dart:convert' show jsonEncode;

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
    data[kunci] = nilai;
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
}) => {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '$jamMulai - 10:40',
  'jam_mulai': jamMulai,
  'jam_selesai': '10:40',
  'ruang': ruang,
  'matakuliah': nama,
  'detail': '',
};

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Identitas NIM menentukan suffix kunci cache yang dibaca service.
    ApiClient.instance.setUserInfo('2200001', 'Budi Santoso');
  });

  group('barisHariIni (pure)', () {
    final senin = DateTime(2026, 10, 26); // Senin

    test('terurut jam mulai, tanpa jam di akhir, format jam · matkul · ruang',
        () {
      final agenda = _agendaDenganHari('Senin', [
        _matkul('Basis Data', '10:00'),
        _matkul('Pemrograman Web', '07:30'),
        {
          'tipe': 'skripsi',
          'hari': 'Senin',
          'jam': '-',
          'ruang': '',
          'matakuliah': 'Bimbingan (belum berjam)',
          'detail': '',
        },
      ]);
      final baris = WidgetJadwalService.barisHariIni(agenda, senin);
      expect(baris.length, 3);
      expect(baris[0], startsWith('07:30 · Pemrograman Web · LT2'));
      expect(baris[1], startsWith('10:00 · Basis Data · LT2'));
      // Baris tanpa jam di akhir, tanpa suffix ruang kosong.
      expect(baris[2], '- · Bimbingan (belum berjam)');
    });

    test('maksimal 4 baris', () {
      final agenda = _agendaDenganHari('Senin', [
        _matkul('A', '07:00'),
        _matkul('B', '08:00'),
        _matkul('C', '09:00'),
        _matkul('D', '10:00'),
        _matkul('E', '11:00'),
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
    test('data null → keadaan tanpa_data + baris dikosongkan', () async {
      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);

      await service.terapkan(data: null, hariIni: DateTime(2026, 10, 26));

      expect(gateway.data['keadaan'], 'tanpa_data');
      expect(gateway.data['baris1'], isNull);
      expect(gateway.data['baris4'], isNull);
      expect(gateway.jumlahPerbaruiWidget, 1);
    });

    test('agenda ada tapi hari ini kosong → keadaan kosong', () async {
      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);
      final senin = DateTime(2026, 10, 26);

      await service.terapkan(
        data: _agendaDenganHari('Selasa', [_matkul('X', '07:30')]),
        hariIni: senin,
      );

      expect(gateway.data['keadaan'], 'kosong');
    });

    test('ada kelas hari ini → keadaan ada + judul + baris terisi', () async {
      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);
      final jumat = DateTime(2026, 10, 23); // Jumat

      await service.terapkan(
        data: _agendaDenganHari('Jumat', [_matkul('Jaringan', '09:00', ruang: 'D.1.1')]),
        hariIni: jumat,
      );

      expect(gateway.data['keadaan'], 'ada');
      expect(gateway.data['judul_tanggal'], 'Jadwal Hari Ini · Jumat, 23 Okt');
      expect(gateway.data['baris1'], '09:00 · Jaringan · D.1.1');
      expect(gateway.data['baris2'], isNull);
    });
  });

  group('perbaruiDariCache (fail-open)', () {
    test('cache berisi agenda hari ini → keadaan ada', () async {
      final hariIni = DateTime.now();
      const namaHari = 'Senin';
      // Pakai Senin supaya fixture cocok untuk tanggal Senin berapa pun.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('agenda_terpadu_cache_2200001', jsonEncode({
        'total_agenda': 1,
        'agenda': {
          namaHari: [_matkul('Pemrograman Web', '09:00')],
        },
      }));

      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);

      await service.perbaruiDariCache();

      expect(gateway.data['keadaan'],
          hariIni.weekday == DateTime.monday ? 'ada' : 'kosong');
    });

    test('cache kosong → keadaan tanpa_data, tanpa melempar', () async {
      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);

      await service.perbaruiDariCache();

      expect(gateway.data['keadaan'], 'tanpa_data');
      expect(gateway.jumlahPerbaruiWidget, 1);
    });
  });

  group('bersihkanSaatLogout', () {
    test('mengembalikan widget ke tanpa_data', () async {
      final gateway = _GatewayPalsu();
      final service = WidgetJadwalService.instance..gantiGatewayUntukTest(gateway);

      await service.bersihkanSaatLogout();

      expect(gateway.data['keadaan'], 'tanpa_data');
      expect(gateway.data['baris1'], isNull);
    });
  });

  tearDown(() {
    // Kembalikan gateway asli supaya test lain tidak memakai gateway palsu.
    WidgetJadwalService.instance.gantiGatewayUntukTest(HomeWidgetGateway());
  });
}
