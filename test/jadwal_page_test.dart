// JadwalPage: declutter hari & bucket. Baris hari biasa TANPA jam pakai
// (jam_mulai '-' / kosong dan jam warisan kosong) tidak lagi dirender, bucket
// "Tanpa Jadwal" tetap tampil sebagai pengingat Skripsi tetapi praktikumnya
// dibuang, "Lainnya" dibiarkan utuh, dan chip "Semua (N)" menghitung baris yang
// benar-benar tampil (bukan total_agenda backend).

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_amikom/pages/jadwal_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/utils/waktu.dart';

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

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

DateTime _hariIniUjian() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _iso(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

String _ddmmyyyy(DateTime t) {
  final d = t.day.toString().padLeft(2, '0');
  final m = t.month.toString().padLeft(2, '0');
  return '$d-$m-${t.year}';
}

Map<String, dynamic> _payload(
  Map<String, List<Map<String, dynamic>>> days, {
  int? total,
}) => {
  'total_agenda': total ?? days.values.fold<int>(0, (sum, l) => sum + l.length),
  'agenda': days,
};

Map<String, dynamic> _senin(List<Map<String, dynamic>> items, {int? total}) =>
    _payload({'Senin': items}, total: total ?? items.length);

// ── Baris kuliah berjadwal (portal): jam_mulai terisi ────────────────────────

final _kuliahTeoriBerjadwal = {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '08:00 - 09:40',
  'jam_mulai': '07:30',
  'ruang': 'D.3.J',
  'matakuliah': 'Pemrograman Mobile',
  'detail': 'Dosen: Budi',
  'komponen': 'teori',
};

final _kuliahPraktekBerjadwal = {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '07:00 - 09:30',
  'ruang': 'Lab Jaringan',
  'matakuliah': 'Jaringan Komputer',
  'detail': 'Dosen: Sari',
  'komponen': 'praktek',
};

final _asistenBerjadwal = {
  'tipe': 'asisten',
  'hari': 'Senin',
  'jam': '10:00 - 12:00',
  'ruang': 'Lab 1',
  'matakuliah': 'Asistensi Praktikum',
  'detail': 'Dosen: Rina',
};

final _ujianBerjadwal = {
  'tipe': 'uas',
  'hari': 'Senin',
  'jam': '08:00 - 10:00',
  'ruang': 'AULA',
  'matakuliah': 'Ujian Akhir Semester',
  'detail': '',
};

// ── Baris tanpa jam pakai: penanda '-' dari portal ───────────────────────────

final _kuliahPraktekTanpaJam = {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '',
  'jam_mulai': '-',
  'ruang': '-',
  'matakuliah': 'Praktikum Big Data',
  'detail': '',
  'komponen': 'praktek',
};

final _kuliahTeoriTanpaJam = {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '',
  'jam_mulai': '-',
  'ruang': '-',
  'matakuliah': 'Skripsi',
  'detail': 'Dosen: Andi',
  'komponen': 'teori',
};

// ── Respons warisan: hanya `jam` terisi, tanpa `komponen` ────────────────────

final _kuliahWarisanBerjadwal = {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '09:00 - 10:40',
  'ruang': 'D.3.J',
  'matakuliah': 'Kuliah Umum',
  'detail': 'Dosen: Rina',
};

final _kuliahWarisanTanpaJam = {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '',
  'ruang': '-',
  'matakuliah': 'Rapat Warisan',
  'detail': 'Dosen: Rina',
};

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  Future<void> pumpJadwal(WidgetTester tester, _FakeAdapter adapter) async {
    ApiClient.instance.dio.httpClientAdapter = adapter;
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const JadwalPage()),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  testWidgets(
    'baris hari biasa tanpa jam tidak dirender, berjam tetap tampil',
    (tester) async {
      await pumpJadwal(
        tester,
        _FakeAdapter(
          _senin([
            _kuliahTeoriBerjadwal,
            _kuliahPraktekBerjadwal,
            _kuliahWarisanBerjadwal,
            _kuliahPraktekTanpaJam,
            _kuliahWarisanTanpaJam,
          ]),
        ),
      );

      expect(tester.takeException(), isNull);
      // Chip jam mengutamakan `jam_mulai`; warisan (tanpa jam_mulai) jatuh ke
      // `jam` — sama seperti tab KRS.
      expect(find.text('07:30'), findsOneWidget);
      expect(find.text('07:00 - 09:30'), findsOneWidget);
      expect(find.text('09:00 - 10:40'), findsOneWidget);

      // Berjam → tampil (termasuk praktikum & respons warisan).
      expect(find.text('Pemrograman Mobile'), findsOneWidget);
      expect(find.text('Jaringan Komputer'), findsOneWidget);
      expect(find.text('Kuliah Umum'), findsOneWidget);

      // Tanpa jam pakai → tidak dirender di hari mana pun.
      expect(find.text('Praktikum Big Data'), findsNothing);
      expect(find.text('Rapat Warisan'), findsNothing);
      // Seksi hari tetap ada (masih ada baris berjam).
      expect(find.text('SENIN'), findsOneWidget);
      expect(find.text('3 kegiatan'), findsOneWidget);
    },
  );

  testWidgets('hari yang semua barisnya tersaring tidak membuat seksi', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _payload({
          'Senin': [_kuliahTeoriBerjadwal],
          'Selasa': [_kuliahPraktekTanpaJam, _kuliahWarisanTanpaJam],
        }),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('SENIN'), findsOneWidget);
    expect(find.text('SELASA'), findsNothing);
    expect(find.text('2 kegiatan'), findsNothing);
  });

  testWidgets('bucket Tanpa Jadwal tetap tampil sebagai pengingat Skripsi', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _payload({
          'Senin': [_kuliahTeoriBerjadwal],
          'Tanpa Jadwal': [
            {
              'tipe': 'kuliah',
              'hari': 'Tanpa Jadwal',
              'jam': '',
              'ruang': '-',
              'matakuliah': 'Skripsi',
              'detail': 'Dosen: Andi',
            },
          ],
        }),
      ),
    );

    expect(tester.takeException(), isNull);
    // AppSection mengapitalkan judul; label bucket dari agendaDayLabel.
    expect(find.text('BELUM ADA JADWAL'), findsOneWidget);
    // Baris warisan tanpa komponen tetap tampil di bucket ini.
    expect(find.text('Skripsi'), findsOneWidget);
    // Seksi hari biasa tetap ada.
    expect(find.text('SENIN'), findsOneWidget);
  });

  testWidgets('bucket Tanpa Jadwal membuang praktikum tapi menyimpan teori', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _payload({
          'Senin': [_kuliahTeoriBerjadwal],
          'Tanpa Jadwal': [
            {..._kuliahTeoriTanpaJam, 'hari': 'Tanpa Jadwal'},
            {
              'tipe': 'kuliah',
              'hari': 'Tanpa Jadwal',
              'jam': '',
              'ruang': '-',
              'matakuliah': 'Bimbingan Akademik',
              'detail': 'Dosen: Sari',
              'komponen': 'teori',
            },
            {
              ..._kuliahPraktekTanpaJam,
              'hari': 'Tanpa Jadwal',
              'ruang': 'Lab Big Data',
            },
          ],
        }),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('BELUM ADA JADWAL'), findsOneWidget);
    // teori & tanpa-komponen tetap, praktikum dibuang dari bucket.
    expect(find.text('Skripsi'), findsOneWidget);
    expect(find.text('Bimbingan Akademik'), findsOneWidget);
    expect(find.text('Praktikum Big Data'), findsNothing);
    // Trailing seksi menghitung baris yang benar-benar tampil.
    expect(find.text('2 kegiatan'), findsOneWidget);
    expect(find.text('3 kegiatan'), findsNothing);
  });

  testWidgets('bucket Lainnya dibiarkan utuh, termasuk baris tanpa jam', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _payload({
          'Senin': [_kuliahTeoriBerjadwal],
          'Lainnya': [
            {..._kuliahPraktekTanpaJam, 'hari': 'Lainnya'},
            {
              'tipe': 'asisten',
              'hari': 'Lainnya',
              'jam': '',
              'ruang': '-',
              'matakuliah': 'Agenda Lain',
              'detail': '',
            },
          ],
        }),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('LAINNYA'), findsOneWidget);
    expect(find.text('Praktikum Big Data'), findsOneWidget);
    expect(find.text('Agenda Lain'), findsOneWidget);
    expect(find.text('2 kegiatan'), findsOneWidget);
  });

  testWidgets(
    'chip Semua menghitung baris tampil, bukan total_agenda backend',
    (tester) async {
      await pumpJadwal(
        tester,
        _FakeAdapter(
          _payload({
            'Senin': [
              _kuliahTeoriBerjadwal,
              _kuliahPraktekBerjadwal,
              _kuliahWarisanBerjadwal,
              _kuliahPraktekTanpaJam,
              _kuliahWarisanTanpaJam,
            ],
            'Tanpa Jadwal': [
              {..._kuliahTeoriTanpaJam, 'hari': 'Tanpa Jadwal'},
              {..._kuliahPraktekTanpaJam, 'hari': 'Tanpa Jadwal'},
            ],
            // total_agenda backend sengaja dibuat lebih besar dari kenyataan.
          }, total: 99),
        ),
      );

      expect(tester.takeException(), isNull);
      // 3 baris Senin + 1 baris bucket = 4 baris tampil.
      expect(find.text('Semua (4)'), findsOneWidget);
      expect(find.text('Semua (99)'), findsNothing);
      expect(find.text('Semua (6)'), findsNothing);
    },
  );

  testWidgets('chip Kuliah menyaring hanya baris kuliah', (tester) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _senin([
          _kuliahTeoriBerjadwal,
          _asistenBerjadwal,
          _ujianBerjadwal,
          _kuliahPraktekBerjadwal,
        ]),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Kuliah 📘'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
    expect(find.text('Jaringan Komputer'), findsOneWidget);
    expect(find.text('Asistensi Praktikum'), findsNothing);
    expect(find.text('Ujian Akhir Semester'), findsNothing);
  });

  testWidgets('semua baris tersaring dan tanpa bucket memakai keadaan kosong', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _senin([
          _kuliahPraktekTanpaJam,
          _kuliahTeoriTanpaJam,
          _kuliahWarisanTanpaJam,
        ]),
      ),
    );

    expect(tester.takeException(), isNull);
    // Data ada tapi tidak ada yang layak tampil → pesan jujur, bukan
    // "belum ada agenda" yang menyesatkan.
    expect(
      find.text(
        'Jadwal yang tersimpan belum punya jam, jadi belum bisa '
        'ditampilkan. Tarik ke bawah untuk menyegarkan.',
      ),
      findsOneWidget,
    );
    expect(find.text('Belum ada agenda'), findsOneWidget);
    // Tidak ada seksi hari; chip filter tetap ada (Semua (0)) sebagai jalan
    // keluar, tapi tak ada baris yang ditampilkan.
    expect(find.text('SENIN'), findsNothing);
    expect(find.text('Semua (0)'), findsOneWidget);
    expect(find.text('Skripsi'), findsNothing);
  });

  testWidgets(
    'satu mata kuliah teori berjadwal + praktikum tanpa jam hanya tampil '
    'sebagai baris teorinya',
    (tester) async {
      await pumpJadwal(
        tester,
        _FakeAdapter(
          _senin([
            {..._kuliahTeoriBerjadwal, 'matakuliah': 'Basis Data'},
            {..._kuliahPraktekTanpaJam, 'matakuliah': 'Basis Data'},
            _asistenBerjadwal,
          ]),
        ),
      );

      expect(tester.takeException(), isNull);
      // Praktikum tanpa jam dibuang, jadi mata kuliah yang sama hanya sekali.
      expect(find.text('Basis Data'), findsOneWidget);
      expect(find.text('Semua (2)'), findsOneWidget);
      // Baris tak hilang diam-diam: praktikum praktis sebagai pengingat tetap
      // tercermin pada hitungan baris yang tampil (2 = Basis Data + asisten).
      expect(find.text('Asistensi Praktikum'), findsOneWidget);
    },
  );

  testWidgets('galat memuat jadwal tetap memakai AppErrorState + coba lagi', (
    tester,
  ) async {
    ApiClient.instance.dio.httpClientAdapter = _FailingAdapter();

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const JadwalPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Belum ada agenda'), findsNothing);
  });

  testWidgets('filter tanpa baris tetap menyediakan jalan keluar ke Semua', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(_senin([_kuliahTeoriBerjadwal, _asistenBerjadwal])),
    );

    expect(tester.takeException(), isNull);
    // Tidak ada baris ujian → chip Ujian menghasilkan keadaan kosong.
    await tester.tap(find.text('Ujian 🔴'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(
      find.text(
        'Tidak ada jadwal untuk filter ini. Pilih "Semua" untuk '
        'melihat seluruh agenda.',
      ),
      findsOneWidget,
    );
    // Chip filter tetap ada (regresi: jangan sampai jalan buntu).
    expect(find.text('Semua (2)'), findsOneWidget);

    // Kembali ke "Semua" memulihkan isi halaman.
    await tester.tap(find.text('Semua (2)'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
  });

  testWidgets(
    'agenda benar-benar kosong memakai pesan jujur, bukan salah label',
    (tester) async {
      await pumpJadwal(
        tester,
        _FakeAdapter(
          _payload({'Senin': [], 'Tanpa Jadwal': [], 'Lainnya': []}),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Tidak ada jadwal agenda terpadu untuk ditampilkan. '
          'Tarik ke bawah untuk menyegarkan.',
        ),
        findsOneWidget,
      );
      // Bukan pesan "belum punya jam" — datanya memang belum ada.
      expect(find.textContaining('belum punya jam'), findsNothing);
    },
  );

  testWidgets('marker jam "-" dari portal diperlakukan sebagai kosong', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _senin([
          _kuliahTeoriBerjadwal,
          {
            'tipe': 'kuliah',
            'hari': 'Senin',
            'jam': '-',
            'jam_mulai': '',
            'ruang': 'D.3.J',
            'matakuliah': 'Praktikum Marker',
            'detail': '',
            'komponen': 'praktek',
          },
        ]),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Praktikum Marker'), findsNothing);
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
  });

  testWidgets('baris berjam di bucket Tanpa Jadwal tetap tampil', (
    tester,
  ) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _payload({
          'Tanpa Jadwal': [
            {
              'tipe': 'kuliah',
              'hari': 'Tanpa Jadwal',
              'jam': '10:00 - 11:40',
              'jam_mulai': '10:00',
              'ruang': 'D.3.R',
              'matakuliah': 'Praktikum Terjadwal',
              'detail': '',
              'komponen': 'praktek',
            },
            {..._kuliahTeoriTanpaJam, 'hari': 'Tanpa Jadwal'},
          ],
        }),
      ),
    );

    expect(tester.takeException(), isNull);
    // Berjam → tampil walau komponen praktek dan walau duduk di bucket.
    expect(find.text('Praktikum Terjadwal'), findsOneWidget);
    // Teori tanpa jam → pertahankan sebagai pengingat Skripsi.
    expect(find.text('Skripsi'), findsOneWidget);
  });

  // ── Gerbang tampil ujian (ambang 7 hari, per-baris, fail-open) ──────────────

  testWidgets('ujian di luar jendela disembunyikan + banner tampil + chip '
      'menghitung baris yang tampil', (tester) async {
    final jauh = _hariIniUjian().add(const Duration(days: 30));
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _senin([
          _kuliahTeoriBerjadwal,
          {..._ujianBerjadwal, 'tanggal': _iso(jauh)},
        ]),
      ),
    );

    expect(tester.takeException(), isNull);
    // Baris ujian disembunyikan dari bucket hari.
    expect(find.text('Ujian Akhir Semester'), findsNothing);
    // Kuliah tetap tampil.
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
    // Banner periode menjelaskan kenapa ujian tak terlihat + tanggalnya.
    expect(find.textContaining('Jadwal ujian terbit'), findsOneWidget);
    expect(find.textContaining(formatTanggalIndo(jauh)), findsOneWidget);
    // Chip & hitungan seksi hanya menghitung baris yang tampil (bukan 2).
    expect(find.text('Semua (1)'), findsOneWidget);
    expect(find.text('1 kegiatan'), findsOneWidget);
  });

  testWidgets('format tanggal warisan dd-MM-yyyy pada baris ujian tetap '
      'digerbangkan', (tester) async {
    final jauh = _hariIniUjian().add(const Duration(days: 30));
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _senin([
          _kuliahTeoriBerjadwal,
          {..._ujianBerjadwal, 'tanggal': _ddmmyyyy(jauh)},
        ]),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ujian Akhir Semester'), findsNothing);
    expect(find.textContaining('Jadwal ujian terbit'), findsOneWidget);
  });

  testWidgets('ujian dalam jendela 7 hari tampil normal tanpa banner', (
    tester,
  ) async {
    final dekat = _hariIniUjian().add(const Duration(days: 3));
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _senin([
          _kuliahTeoriBerjadwal,
          {..._ujianBerjadwal, 'tanggal': _iso(dekat)},
        ]),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ujian Akhir Semester'), findsOneWidget);
    expect(find.textContaining('Jadwal ujian terbit'), findsNothing);
    expect(find.text('Semua (2)'), findsOneWidget);
    expect(find.text('2 kegiatan'), findsOneWidget);
  });

  testWidgets('baris ujian tanpa tanggal (BE lama) fail-open → tampil '
      'seperti semula tanpa banner', (tester) async {
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _senin([
          _kuliahTeoriBerjadwal,
          _ujianBerjadwal, // respons lama: tanpa field `tanggal`
        ]),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ujian Akhir Semester'), findsOneWidget);
    expect(find.textContaining('Jadwal ujian terbit'), findsNothing);
    expect(find.text('Semua (2)'), findsOneWidget);
  });

  testWidgets('tab filter Ujian menampilkan ujian apa adanya walau di luar '
      'jendela (user sengaja memilih melihat ujian)', (tester) async {
    final jauh = _hariIniUjian().add(const Duration(days: 30));
    await pumpJadwal(
      tester,
      _FakeAdapter(
        _senin([
          _kuliahTeoriBerjadwal,
          {..._ujianBerjadwal, 'tanggal': _iso(jauh)},
        ]),
      ),
    );

    // Di tampilan campuran ujian disembunyikan...
    expect(find.text('Ujian Akhir Semester'), findsNothing);

    // ...tetapi tab Ujian tetap bisa dibuka dan menampilkan ujian.
    await tester.tap(find.text('Ujian 🔴'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Ujian Akhir Semester'), findsOneWidget);
    expect(find.textContaining('Jadwal ujian terbit'), findsNothing);
  });
}
