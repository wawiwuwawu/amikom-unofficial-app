// Regresi gerbang tampil ujian di Dashboard "Jadwal Hari Ini": baris ujian
// (tipe uts/uas) di luar jendela [PeriodeUjianService.ambangHariUjian]
// disembunyikan (tanpa banner, fail-open); di dalam jendela tampil normal.
// Pola FakeAdapter seperti test/jadwal_page_test.dart — tanpa Firebase.

import 'dart:convert';
import 'dart:typed_data';

import 'package:app_amikom/pages/dashboard_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/periode_ujian_service.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/utils/waktu.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

DateTime _hariIniUjian() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _ddmmyyyy(DateTime t) {
  final d = t.day.toString().padLeft(2, '0');
  final m = t.month.toString().padLeft(2, '0');
  return '$d-$m-${t.year}';
}

Map<String, dynamic> _barisUjian(String tanggal) => {
      'KODE': 'TIF123',
      'MKL': 'Ujian Akhir Semester',
      'TANGGAL': tanggal,
      'HARI': 'Senin',
      'RUANG': 'AULA',
      'JAM_MULAI': '08:00',
      'JAM_SELESEI': '10:00',
      'NOKURSI': 3,
    };

const _kuliahBerjadwal = {
  'tipe': 'kuliah',
  'hari': 'HariIni',
  'jam': '09:00 - 10:40',
  'jam_mulai': '09:00',
  'ruang': 'D.3.J',
  'matakuliah': 'Pemrograman Mobile',
  'detail': 'Dosen: Budi',
  'komponen': 'teori',
};

class _DashboardAdapter implements HttpClientAdapter {
  _DashboardAdapter({
    required this.agendaHariIni,
    this.uts,
    this.uas,
  });

  final List<Map<String, dynamic>> agendaHariIni;
  List<Map<String, dynamic>>? uts;
  List<Map<String, dynamic>>? uas;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Future<ResponseBody> json(Object data) async => ResponseBody.fromString(
          jsonEncode({'status': 'success', 'data': data}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );

    if (options.path.contains('/api/v1/dashboard')) {
      return json({
        'profile': {
          'npm': '2200001',
          'nama': 'Budi Santoso',
          'prodi': 'Informatika',
          'angkatan': 2022,
          'fakultas': 'FILKOM',
          'email': 'budi@example.com',
          'no_hp': '',
          'pembimbing_akademik': 'Dosen PA',
          'foto_url': '',
        },
        'statistik': {'total_sks': 100, 'ipk': 3.5},
        'status': {'status': 'Aktif'},
      });
    }
    if (options.path.contains('/api/v1/agenda/terpadu')) {
      final hariIni = namaHariDariWeekday(DateTime.now().weekday);
      return json({
        'total_agenda': agendaHariIni.length,
        'agenda': {hariIni: agendaHariIni},
      });
    }
    if (options.path.contains('/api/v1/sp/rekomendasi')) {
      return json({
        'has_rekomendasi': false,
        'warning_message': '',
        'total_rekomendasi': 0,
        'total_sks': 0,
        'kategori_sangat_dianjurkan': [],
        'kategori_opsional_sks_besar': [],
      });
    }
    if (options.path.contains('/api/v1/akademik/jadwal-ujian')) {
      final rows = options.queryParameters['jenis'] == 'uas' ? uas : uts;
      if (rows == null) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return json(rows);
    }
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> pumpDashboard(
  WidgetTester tester, {
  required List<Map<String, dynamic>> agendaHariIni,
  List<Map<String, dynamic>>? uts,
  List<Map<String, dynamic>>? uas,
}) async {
  PeriodeUjianService.instance.resetUntukTest();
  ApiClient.instance.dio.httpClientAdapter = _DashboardAdapter(
    agendaHariIni: agendaHariIni,
    uts: uts,
    uas: uas,
  );
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: const DashboardPage()),
  );
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  testWidgets('ujian di luar jendela disembunyikan dari Jadwal Hari Ini',
      (tester) async {
    final jauh = _ddmmyyyy(_hariIniUjian().add(const Duration(days: 30)));
    await pumpDashboard(
      tester,
      agendaHariIni: [_kuliahBerjadwal, _ujianAgenda],
      uts: [_barisUjian(jauh)],
      uas: [],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
    expect(find.text('Ujian Akhir Semester'), findsNothing,
        reason: 'ujian sebulan lagi tidak boleh memenuhi beranda');
    // Tanpa banner di dashboard (perilaku berbeda dari JadwalPage).
    expect(find.textContaining('Jadwal ujian terbit'), findsNothing);
  });

  testWidgets('ujian dalam jendela 7 hari tampil normal', (tester) async {
    final dekat = _ddmmyyyy(_hariIniUjian().add(const Duration(days: 3)));
    await pumpDashboard(
      tester,
      agendaHariIni: [_kuliahBerjadwal, _ujianAgenda],
      uts: [_barisUjian(dekat)],
      uas: [],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ujian Akhir Semester'), findsOneWidget);
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
  });

  testWidgets('periode gagal (fail-open) → ujian tampil seperti semula',
      (tester) async {
    await pumpDashboard(
      tester,
      agendaHariIni: [_kuliahBerjadwal, _ujianAgenda],
      uts: null, // fetch jadwal-ujian gagal
      uas: null,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ujian Akhir Semester'), findsOneWidget);
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
  });
}

/// Baris ujian di agenda hari ini (tipe uas, berjam) — sengaja tidak pakai
/// variabel top-level sebelum helper di atas agar urutan baca tetap jelas.
const _ujianAgenda = {
  'tipe': 'uas',
  'hari': 'HariIni',
  'jam': '08:00 - 10:00',
  'ruang': 'AULA',
  'matakuliah': 'Ujian Akhir Semester',
  'detail': '',
};
