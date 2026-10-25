// Regresi: tab "Cetak & Jadwal" di halaman KRS memakai tampilannya SENDIRI
// (KrsJadwalTab), bukan JadwalPage. Halaman ini hanya boleh menampilkan mata
// kuliah KRS — filter Asisten/Ujian milik JadwalPage tidak boleh muncul di sini.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_amikom/pages/krs/krs_jadwal_tab.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/widgets/app_kit.dart';

class _FakeAdapter implements HttpClientAdapter {
  final Map<String, dynamic> payload;

  _FakeAdapter(this.payload);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

Map<String, dynamic> _agendaPayload({
  List<Map<String, dynamic>> items = const [],
  int total = 0,
}) =>
    {
      'total_agenda': total,
      'agenda': {
        'Senin': items,
      },
    };

final _kuliahPemrograman = {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '07:00 - 09:30',
  'ruang': 'D.3.J',
  'matakuliah': 'Pemrograman Mobile',
  'detail': 'Dosen: Budi, S.Kom.',
};

final _kuliahBasisData = {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '13:00 - 15:30',
  'ruang': 'D.3.K',
  'matakuliah': 'Basis Data',
  'detail': '',
};

final _asisten = {
  'tipe': 'asisten',
  'hari': 'Senin',
  'jam': '10:00 - 12:00',
  'ruang': 'Lab 1',
  'matakuliah': 'Asistensi Praktikum',
  'detail': '',
};

final _ujian = {
  'tipe': 'uas',
  'hari': 'Senin',
  'jam': '08:00 - 10:00',
  'ruang': 'AULA',
  'matakuliah': 'Ujian Akhir Semester',
  'detail': '',
};

// ── Fixtures komponen (jadwal portal: teori/praktek + jam_mulai) ─────────────

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
  'ruang': '-',
  'matakuliah': 'Skripsi',
  'detail': 'Dosen: Andi',
  'komponen': 'teori',
};

final _kuliahWarisanTanpaJam = {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '',
  'ruang': 'D.3.J',
  'matakuliah': 'Kuliah Umum',
  'detail': 'Dosen: Rina',
};

final _kuliahWarisanBerjadwal = {
  'tipe': 'kuliah',
  'hari': 'Senin',
  'jam': '09:00 - 10:40',
  'jam_mulai': '-',
  'ruang': 'D.3.J',
  'matakuliah': 'Kuliah Umum',
  'detail': 'Dosen: Rina',
};

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  testWidgets('tab KRS hanya menampilkan mata kuliah, tanpa filter agenda',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [_kuliahPemrograman, _asisten, _kuliahBasisData, _ujian],
      total: 4,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);

    // Mata kuliah KRS tampil… (satu di baris hari, satu di Ringkasan)
    expect(find.text('Pemrograman Mobile'), findsNWidgets(2));
    expect(find.text('Basis Data'), findsNWidgets(2));
    expect(find.text('2 mata kuliah di KRS'), findsOneWidget);

    // …tetapi agenda Asisten/Ujian TIDAK boleh bocor ke tab KRS.
    expect(find.text('Asistensi Praktikum'), findsNothing);
    expect(find.text('Ujian Akhir Semester'), findsNothing);

    // Filter milik JadwalPage tidak boleh ada di sini.
    expect(find.text('Asisten 🟣'), findsNothing);
    expect(find.text('Ujian 🔴'), findsNothing);
    expect(find.text('Kuliah 📘'), findsNothing);

    // Tombol cetak/bagikan KRS tetap tersedia di tab ini.
    expect(find.byTooltip('Unduh KRS'), findsOneWidget);
    expect(find.byTooltip('Bagikan KRS'), findsOneWidget);
  });

  testWidgets('agenda tanpa mata kuliah menampilkan keadaan kosong jujur',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [_asisten, _ujian],
      total: 2,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Belum ada jadwal kuliah'), findsOneWidget);
    expect(find.text('Pemrograman Mobile'), findsNothing);
  });

  testWidgets('galat memuat jadwal KRS memakai AppErrorState + coba lagi',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FailingAdapter();

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('baris alat menghitung mata kuliah unik, bukan jumlah baris',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [
        _kuliahPemrograman,
        {..._kuliahPemrograman, 'jam': '13:00 - 15:30'},
        _kuliahBasisData,
      ],
      total: 3,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    // Tiga baris, dua mata kuliah unik — tidak ada hitungan per baris.
    expect(find.text('2 mata kuliah di KRS'), findsOneWidget);
    expect(find.text('3 mata kuliah di KRS'), findsNothing);
    expect(find.text('3 mata kuliah'), findsNothing);
  });

  testWidgets('komponen praktek berjadwal tampil sebagai Praktikum di hari',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [_kuliahPraktekBerjadwal],
      total: 1,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    // Tetap di seksi hari (bukan seksi "tanpa jadwal")…
    expect(find.text('SENIN'), findsOneWidget);
    expect(find.text('TANPA PRAKTIKUM'), findsNothing);
    // …dengan pil "Praktikum" pada barisnya.
    expect(
      find.ancestor(of: find.text('Praktikum'), matching: find.byType(AppPill)),
      findsOneWidget,
    );
    // Chip jam memakai `jam` warisan saat `jam_mulai` tidak dikirim portal.
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('07:00 - 09:30'), findsNothing);
  });

  testWidgets('komponen praktek tanpa jam masuk seksi TANPA PRAKTIKUM',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [_kuliahPraktekTanpaJam],
      total: 1,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('TANPA PRAKTIKUM'), findsOneWidget);
    expect(find.text('TANPA KELAS'), findsNothing);
    // Tidak dirender di seksi hari mana pun — hari ini kehilangan satu-satunya
    // barisnya jadi seksi hari tidak dibuat.
    expect(find.text('SENIN'), findsNothing);
    // Satu di baris seksi, satu di baris ringkasan.
    expect(find.text('Praktikum Big Data'), findsNWidgets(2));
    // Tetap bukan keadaan kosong: mata kuliahnya ADA, hanya belum berjadwal.
    expect(find.text('Belum ada jadwal kuliah'), findsNothing);
    expect(find.text('1 mata kuliah di KRS'), findsOneWidget);
  });

  testWidgets('komponen teori tanpa jam masuk seksi TANPA KELAS',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [_kuliahTeoriTanpaJam],
      total: 1,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('TANPA KELAS'), findsOneWidget);
    expect(find.text('TANPA PRAKTIKUM'), findsNothing);
    expect(find.text('SENIN'), findsNothing);
    expect(find.text('Skripsi'), findsNWidgets(2));
    // Penjelasan mengapa kosongnya wajar tetap tampil.
    expect(
      find.text(
        'Belum ada jadwal kelas tetap (biasanya Skripsi atau bimbingan). '
        'Hubungi dosen pembimbing untuk mengatur jadwal bimbingan.',
      ),
      findsOneWidget,
    );
    expect(find.text('Tanpa kelas'), findsOneWidget);
  });

  testWidgets('respons warisan tanpa komponen tetap masuk tampilan hari',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [_kuliahWarisanTanpaJam],
      total: 1,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    // Tanpa komponen = perilaku lama: tetap di seksi hari seperti bucket
    // "Tanpa Jadwal", tidak dianggap kekurangan praktikum/kelas.
    expect(find.text('SENIN'), findsOneWidget);
    expect(find.text('TANPA PRAKTIKUM'), findsNothing);
    expect(find.text('TANPA KELAS'), findsNothing);
    expect(find.text('Kuliah Umum'), findsNWidgets(2));
  });

  testWidgets('toolbar menghitung mata kuliah unik, bukan baris', (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [
        _kuliahTeoriBerjadwal,
        _kuliahPraktekBerjadwal,
        {..._kuliahBasisData, 'komponen': 'teori'},
        {
          ..._kuliahBasisData,
          'jam': '13:00 - 15:30',
          'ruang': 'Lab Basis Data',
          'komponen': 'praktek',
        },
        _kuliahTeoriTanpaJam,
        _kuliahPraktekTanpaJam,
        _kuliahWarisanBerjadwal,
      ],
      total: 7,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    // Tujuh baris → enam mata kuliah unik (Basis Data punya teori + praktikum).
    expect(find.text('6 mata kuliah di KRS'), findsOneWidget);
    expect(find.text('7 mata kuliah'), findsNothing);

    // Pil baris memakai komponen; chip jam mengutamakan jam_mulai lalu jam.
    expect(
      find.ancestor(
        of: find.text('Praktikum'),
        matching: find.byType(AppPill),
      ),
      findsNWidgets(2),
    );
    expect(find.text('Kuliah Teori'), findsNWidgets(2));
    expect(find.text('07:30'), findsOneWidget);
    expect(find.text('08:00 - 09:40'), findsNothing);
    expect(find.text('09:00'), findsOneWidget);
  });

  testWidgets('ringkasan menampilkan satu baris per mata kuliah + status',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [
        _kuliahTeoriBerjadwal,
        _kuliahPraktekBerjadwal,
        {..._kuliahBasisData, 'komponen': 'teori'},
        {
          ..._kuliahBasisData,
          'jam': '13:00 - 15:30',
          'ruang': 'Lab Basis Data',
          'komponen': 'praktek',
        },
        _kuliahTeoriTanpaJam,
        _kuliahPraktekTanpaJam,
        _kuliahWarisanBerjadwal,
      ],
      total: 7,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);

    // Ringkasan ada di paling bawah ListView (lazy build) — gulir dulu.
    await tester.scrollUntilVisible(
      find.text('RINGKASAN MATA KULIAH'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('RINGKASAN MATA KULIAH'), findsOneWidget);
    expect(find.text('6 mata kuliah'), findsOneWidget);

    // Status ringkasan mengikuti komponen & jam tiap mata kuliah.
    expect(find.text('Teori'), findsOneWidget);
    expect(find.text('Teori & Praktikum'), findsOneWidget);
    expect(find.text('Tanpa kelas'), findsOneWidget);
    expect(find.text('Teori (tanpa praktikum)'), findsOneWidget);
    expect(find.text('Dosen: Rina'), findsNWidgets(2)); // pil baris + status
  });

  testWidgets('komponen dinormalkan (kapital/spasi) & nilai tak dikenal aman',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [
        {..._kuliahTeoriBerjadwal, 'komponen': ' teoRi '},
        {..._kuliahPraktekBerjadwal, 'komponen': 'PRAKTEK'},
        {
          'tipe': 'kuliah',
          'hari': 'Senin',
          'jam': '10:00 - 11:40',
          'ruang': 'D.3.M',
          'matakuliah': 'Kuliah Seminar',
          'detail': 'Dosen: Rina',
          'komponen': 'seminar',
        },
      ],
      total: 3,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    // ' teoRi ' → teori, 'PRAKTEK' → praktek, 'seminar' → default (detail).
    expect(find.text('Kuliah Teori'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Praktikum'),
        matching: find.byType(AppPill),
      ),
      findsOneWidget,
    );
    expect(find.text('Dosen: Rina'), findsNWidgets(2)); // pil + subjudul baris
    // Tanpa jam tak ada → tak boleh ada seksi "tanpa …".
    expect(find.text('TANPA PRAKTIKUM'), findsNothing);
    expect(find.text('TANPA KELAS'), findsNothing);
  });

  testWidgets('semua baris tanpa jam tak lagi membuat layar kosong',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [
        _kuliahPraktekTanpaJam,
        _kuliahTeoriTanpaJam,
      ],
      total: 2,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    // Tak ada baris berjadwal → tak ada seksi hari yang dirender.
    expect(find.text('SENIN'), findsNothing);
    expect(find.text('Belum ada jadwal kuliah'), findsNothing);
    expect(find.text('TANPA PRAKTIKUM'), findsOneWidget);
    expect(find.text('TANPA KELAS'), findsOneWidget);
    expect(find.text('2 mata kuliah di KRS'), findsOneWidget);
  });

  testWidgets('satu mata kuliah teori+praktikum tetap dihitung sekali',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_agendaPayload(
      items: [
        {..._kuliahPraktekTanpaJam, 'matakuliah': 'Basis Data'},
        {..._kuliahTeoriTanpaJam, 'matakuliah': 'Basis Data'},
      ],
      total: 2,
    ));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const KrsJadwalTab()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('1 mata kuliah di KRS'), findsOneWidget);
    expect(find.text('TANPA PRAKTIKUM'), findsOneWidget);
    expect(find.text('TANPA KELAS'), findsOneWidget);
    // Tiga widget: dua baris seksi + satu baris ringkasan.
    expect(find.text('Basis Data'), findsNWidgets(3));
  });
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
