// Regresi: tab "Cetak & Jadwal" di halaman KRS memakai tampilannya SENDIRI
// (KrsJadwalTab), bukan JadwalPage. Halaman ini hanya boleh menampilkan mata
// kuliah KRS — filter Asisten/Ujian milik JadwalPage tidak boleh muncul di sini.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_amikom/pages/krs/krs_jadwal_tab.dart';
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

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
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

    // Mata kuliah KRS tampil…
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
    expect(find.text('Basis Data'), findsOneWidget);
    expect(find.text('2 mata kuliah terjadwal'), findsOneWidget);

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
