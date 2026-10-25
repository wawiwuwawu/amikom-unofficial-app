// JadwalPage mode mingguan (grid kalender gaya Google Calendar):
// toggle Hari/Minggu yang dipersist di SharedPreferences, blok agenda di
// kolom hari & jam yang benar, ujian ber-tanggal (dalam / luar minggu),
// overlap dua agenda, navigasi minggu, dan filter tipe di kedua mode.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/pages/jadwal_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';

class _FakeAdapter implements HttpClientAdapter {
  final Map<String, dynamic> payload;

  _FakeAdapter(this.payload);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!options.path.contains('/api/v1/agenda/terpadu')) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'status': 'success', 'data': payload}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DateTime _hariIniUjian() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Senin pukul 00:00 dari minggu yang memuat [t] — sama dengan halaman.
DateTime _seninDari(DateTime t) =>
    DateTime(t.year, t.month, t.day).subtract(Duration(days: t.weekday - 1));

String _iso(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

const _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Label rentang minggu — replikasi logika halaman untuk assert.
String _labelMinggu(DateTime mulai) {
  final akhir = mulai.add(const Duration(days: 6));
  if (mulai.month == akhir.month && mulai.year == akhir.year) {
    return '${mulai.day}–${akhir.day} ${_bulanPendek[mulai.month - 1]} '
        '${mulai.year}';
  }
  if (mulai.year == akhir.year) {
    return '${mulai.day} ${_bulanPendek[mulai.month - 1]} – '
        '${akhir.day} ${_bulanPendek[akhir.month - 1]} ${mulai.year}';
  }
  return '${mulai.day} ${_bulanPendek[mulai.month - 1]} ${mulai.year} – '
      '${akhir.day} ${_bulanPendek[akhir.month - 1]} ${akhir.year}';
}

Map<String, dynamic> _payload(
  Map<String, List<Map<String, dynamic>>> days,
) => {
  'total_agenda': days.values.fold<int>(0, (sum, l) => sum + l.length),
  'agenda': days,
};

final _kuliahSenin = {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '08:00 - 09:40',
  'jam_mulai': '08:00',
  'ruang': 'D.3.J',
  'matakuliah': 'Pemrograman Mobile',
  'detail': 'Dosen: Budi',
  'komponen': 'teori',
};

final _asistenSenin = {
  'tipe': 'asisten',
  'hari': 'Senin',
  'jam': '10:00 - 12:00',
  'ruang': 'Lab 1',
  'matakuliah': 'Asistensi Praktikum',
  'detail': 'Dosen: Rina',
};

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    // Halaman membaca mode tampilan + cache dari SharedPreferences; tanpa
    // mock, channel plugin tidak pernah selesai di lingkungan test.
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpJadwal(WidgetTester tester, _FakeAdapter adapter) async {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.dio.httpClientAdapter = adapter;
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const JadwalPage()),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Future<void> keModeMinggu(WidgetTester tester) async {
    await tester.tap(find.text('Minggu'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  testWidgets('default mode hari, toggle ke minggu tersimpan di prefs', (
    tester,
  ) async {
    await pumpJadwal(tester, _FakeAdapter(_payload({'Senin': [_kuliahSenin]})));

    // Default 'hari': seksi daftar per hari tampil, header mingguan tidak.
    expect(tester.takeException(), isNull);
    expect(find.text('SENIN'), findsOneWidget);
    expect(find.textContaining('–'), findsNothing);

    // Pindah ke minggu: header rentang minggu muncul + pref tersimpan.
    await keModeMinggu(tester);
    final senin = _seninDari(_hariIniUjian());
    expect(find.text(_labelMinggu(senin)), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('jadwal_mode_tampilan'), 'minggu');

    // Kembali ke hari: pref ikut berubah.
    await tester.tap(find.text('Hari'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final prefsSetelah = await SharedPreferences.getInstance();
    expect(prefsSetelah.getString('jadwal_mode_tampilan'), 'hari');
  });

  testWidgets('mode tersimpan di prefs dipakai saat halaman dibuka ulang', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'jadwal_mode_tampilan': 'minggu'});
    ApiClient.instance.dio.httpClientAdapter =
        _FakeAdapter(_payload({'Senin': [_kuliahSenin]}));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const JadwalPage()),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text(_labelMinggu(_seninDari(_hariIniUjian()))), findsOneWidget);
    expect(find.text('SENIN'), findsNothing);
  });

  testWidgets('mode minggu menampilkan blok agenda di kolom & jam yang benar', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(_payload({'Senin': [_kuliahSenin, _asistenSenin]})),
    );
    await keModeMinggu(tester);

    expect(tester.takeException(), isNull);
    // Blok per matkul tampil dengan jam mulai di dalamnya.
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
    expect(find.text('Asistensi Praktikum'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    // Header hari memakai singkatan Indonesia.
    expect(find.text('Sen'), findsOneWidget);
    expect(find.text('Min'), findsOneWidget);
  });

  testWidgets('ujian ber-tanggal dalam minggu terlihat tampil; di luar '
      'minggu tidak tampil (tanpa gerbang 7 hari)', (tester) async {
    final minggu = _seninDari(_hariIniUjian());
    final dalamMinggu = minggu.add(const Duration(days: 2));
    final jauh = minggu.add(const Duration(days: 30));

    await pumpJadwal(
      tester,
      _FakeAdapter(_payload({
        'Senin': [
          _kuliahSenin,
          {
            'tipe': 'uas',
            'hari': 'Senin',
            'jam': '08:00 - 10:00',
            'ruang': 'AULA',
            'matakuliah': 'Ujian Dalam Minggu',
            'detail': '',
            'tanggal': _iso(dalamMinggu),
          },
          {
            'tipe': 'uts',
            'hari': 'Senin',
            'jam': '08:00 - 10:00',
            'ruang': 'AULA',
            'matakuliah': 'Ujian Minggu Lain',
            'detail': '',
            'tanggal': _iso(jauh),
          },
        ],
      })),
    );
    await keModeMinggu(tester);

    expect(tester.takeException(), isNull);
    // Ujian minggu ini tampil sebagai blok dengan penanda jenis ujian.
    expect(find.text('Ujian Dalam Minggu'), findsOneWidget);
    expect(find.textContaining('UAS'), findsOneWidget);
    // Ujian minggu lain tidak tampil di minggu berjalan — meski gerbang 7
    // hari mode hari tidak dipakai, kalender hanya menampilkan minggunya.
    expect(find.text('Ujian Minggu Lain'), findsNothing);
    expect(find.textContaining('UTS'), findsNothing);
    // Kuliah mingguan tetap tampil.
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
  });

  testWidgets('ujian tanpa tanggal jatuh ke kolom hari-nya (fail-open)', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(_payload({
        'Senin': [
          {
            'tipe': 'uts',
            'hari': 'Senin',
            'jam': '08:00 - 10:00',
            'ruang': 'AULA',
            'matakuliah': 'Ujian Tanpa Tanggal',
            'detail': '',
          },
        ],
      })),
    );
    await keModeMinggu(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Ujian Tanpa Tanggal'), findsOneWidget);
    expect(find.textContaining('UTS'), findsOneWidget);
  });

  testWidgets('dua agenda bertumpuk di hari sama dibagi lebar tanpa error', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(_payload({
        'Senin': [
          _kuliahSenin, // 08:00 - 09:40
          {
            'tipe': 'kuliah',
            'hari': 'Senin',
            'jam': '08:30 - 11:00',
            'jam_mulai': '08:30',
            'ruang': 'D.3.K',
            'matakuliah': 'Jaringan Komputer',
            'detail': 'Dosen: Sari',
            'komponen': 'teori',
          },
        ],
      })),
    );
    await keModeMinggu(tester);

    // pumpAndSettle di dalam keModeMinggu sudah memastikan tidak ada layout
    // exception saat dua blok tumpang tindih dibagi lebar kolom.
    expect(tester.takeException(), isNull);
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
    expect(find.text('Jaringan Komputer'), findsOneWidget);
  });

  testWidgets('navigasi minggu mengubah label rentang; Hari ini kembali', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(_payload({'Senin': [_kuliahSenin]})),
    );
    await keModeMinggu(tester);

    final mingguDepan = _seninDari(_hariIniUjian()).add(const Duration(days: 7));
    await tester.tap(find.byIcon(CupertinoIcons.chevron_forward));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text(_labelMinggu(mingguDepan)), findsOneWidget);
    expect(find.text(_labelMinggu(_seninDari(_hariIniUjian()))), findsNothing);

    // Tombol "Hari ini" muncul bila minggu berjalan tidak aktif, dan
    // mengembalikan ke minggu berjalan.
    expect(find.text('Hari ini'), findsOneWidget);
    await tester.tap(find.text('Hari ini'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text(_labelMinggu(_seninDari(_hariIniUjian()))), findsOneWidget);

    // Panah kiri mundur satu minggu.
    await tester.tap(find.byIcon(CupertinoIcons.chevron_back));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final mingguLalu = _seninDari(_hariIniUjian()).subtract(
      const Duration(days: 7),
    );
    expect(find.text(_labelMinggu(mingguLalu)), findsOneWidget);
  });

  testWidgets('filter tipe tetap bekerja di mode minggu', (tester) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(_payload({'Senin': [_kuliahSenin, _asistenSenin]})),
    );
    await keModeMinggu(tester);

    expect(find.text('Asistensi Praktikum'), findsOneWidget);

    await tester.tap(find.text('Kuliah 📘'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
    expect(find.text('Asistensi Praktikum'), findsNothing);
  });
}
