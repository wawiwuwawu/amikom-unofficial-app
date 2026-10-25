// Fase 2a — deteksi presensi nyata pada kartu "Sedang berlangsung" beranda:
//   • sudah presensi hari ini (POST /absensi/mahasiswa membawa pertemuan
//     bertanggal hari ini dengan status tercatat) → tombol hilang + teks
//     "Presensi tercatat";
//   • belum presensi → tombol tetap ada;
//   • endpoint absensi gagal → fail-open, tombol tetap ada, tanpa galat UI;
//   • tanpa item berjalan → TIDAK ada request /absensi/ (jangan fetch sia-sia).
// Pola FakeAdapter seperti test/dashboard_gerbang_ujian_test.dart.

import 'dart:convert';
import 'dart:typed_data';

import 'package:app_amikom/pages/dashboard_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/utils/waktu.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bulanIndo = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
  'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _dua(int n) => n.toString().padLeft(2, '0');

/// Format tanggal portal panjang: "Jumat, 24 Oktober 2026" — bentuk nyata
/// field `tanggal` riwayat_pertemuan.
String _tanggalPortalIndo(DateTime t) =>
    '${namaHariDariWeekday(t.weekday)}, ${t.day} ${_bulanIndo[t.month - 1]} ${t.year}';

String _iso(DateTime t) =>
    '${t.year}-${_dua(t.month)}-${_dua(t.day)}';

Map<String, dynamic> _mahasiswaPayload({
  required List<Map<String, dynamic>> riwayat,
}) => {
      'jenis_perkuliahan': 'Teori',
      'nama_dosen': 'Budi',
      'riwayat_pertemuan': riwayat,
      'statistik': {
        'hadir': 80,
        'izin': 0,
        'tanpa_keterangan': 20,
        'sakit': 0,
        'belum_validasi': 0,
        'kehadiran': 80,
      },
    };

/// Item kuliah yang SELALU berjalan (rentang menutupi seluruh hari) —
/// deteksi berjalan tidak boleh tergantung jam eksekusi test.
const _kuliahBerjalan = {
  'tipe': 'kuliah',
  'hari': 'HariIni',
  'jam': '00:00 - 23:59',
  'jam_mulai': '00:00',
  'jam_selesai': '23:59',
  'ruang': 'D.3.J',
  'matakuliah': 'Pemrograman Mobile',
  'detail': 'Dosen: Budi',
  'komponen': 'teori',
};

class _PresensiAdapter implements HttpClientAdapter {
  _PresensiAdapter({required this.agendaHariIni, this.riwayat, this.absensiGagal = false});

  final List<Map<String, dynamic>> agendaHariIni;

  /// Payload riwayat_pertemuan untuk POST /absensi/mahasiswa (null → kosong).
  List<Map<String, dynamic>>? riwayat;

  /// true → semua request /absensi/ melempar connectionError (fail-open).
  final bool absensiGagal;

  /// Log jalur yang diminta — untuk asersi "tidak ada request absensi".
  final List<String> paths = [];
  final List<Map<String, dynamic>> bodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    if (options.data is Map<String, dynamic>) {
      bodies.add(options.data as Map<String, dynamic>);
    }

    Future<ResponseBody> json(Object data) async => ResponseBody.fromString(
      jsonEncode({'status': 'success', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

    if (absensiGagal && options.path.contains('/api/v1/absensi/')) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }

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

    // ── Rantai cek presensi (AbsensiService.sudahPresensiHariIni) ──────────
    if (options.path.contains('/api/v1/absensi/semester')) {
      return json([
        {'value': 'Gasal', 'label': 'Gasal (Ganjil)'},
        {'value': 'Genap', 'label': 'Genap'},
      ]);
    }
    if (options.path.contains('/api/v1/absensi/matkul')) {
      return json([
        {'value': 'Pemrograman Mobile', 'label': 'Pemrograman Mobile'},
      ]);
    }
    if (options.path.contains('/api/v1/absensi/mahasiswa')) {
      return json(_mahasiswaPayload(riwayat: riwayat ?? const []));
    }

    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter yang terpasang pada ApiClient saat [pumpDashboard] — dibaca test
/// untuk asersi log request (jalur + body).
late _PresensiAdapter _adapter;

Future<void> pumpDashboard(
  WidgetTester tester, {
  required List<Map<String, dynamic>> agendaHariIni,
  List<Map<String, dynamic>>? riwayat,
  bool absensiGagal = false,
}) async {
  _adapter = _PresensiAdapter(
    agendaHariIni: agendaHariIni,
    riwayat: riwayat,
    absensiGagal: absensiGagal,
  );
  ApiClient.instance.dio.httpClientAdapter = _adapter;
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: const DashboardPage()),
  );
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('sudah presensi hari ini → tombol hilang + teks Presensi tercatat', (
    tester,
  ) async {
    final now = DateTime.now();
    final kemarin = now.subtract(const Duration(days: 1));
    await pumpDashboard(
      tester,
      agendaHariIni: [_kuliahBerjalan],
      riwayat: [
        // Pertemuan kemarin (ISO, status H) — TIDAK boleh dihitung sebagai
        // presensi hari ini.
        {
          'tanggal': _iso(kemarin),
          'materi': 'Widget',
          'status': 'H',
          'id_presensi': '111',
        },
        // Pertemuan hari ini tercatat.
        {
          'tanggal': _tanggalPortalIndo(now),
          'materi': 'Layout',
          'status': 'H',
          'id_presensi': '900',
        },
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Sedang berlangsung'), findsOneWidget);
    expect(
      find.textContaining('Presensi tercatat'),
      findsOneWidget,
      reason: 'sudah presensi → kartu informatif tanpa tombol',
    );
    expect(find.text('Presensi Sekarang'), findsNothing);

    // Rantai benar: mahasiswa diminta dengan nama matakuliah agenda.
    final mahasiswaBody = _adapter.bodies.lastWhere(
      (b) => b.containsKey('makul'),
    );
    expect(mahasiswaBody['makul'], 'Pemrograman Mobile');
  });

  testWidgets('belum presensi hari ini → tombol Presensi Sekarang tetap ada', (
    tester,
  ) async {
    final kemarin = DateTime.now().subtract(const Duration(days: 1));
    await pumpDashboard(
      tester,
      agendaHariIni: [_kuliahBerjalan],
      riwayat: [
        {
          'tanggal': _iso(kemarin),
          'materi': 'Widget',
          'status': 'H',
          'id_presensi': '111',
        },
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Presensi Sekarang'), findsOneWidget);
    expect(find.textContaining('Presensi tercatat'), findsNothing);
  });

  testWidgets('endpoint absensi gagal → fail-open: tombol tetap ada, tanpa galat', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      agendaHariIni: [_kuliahBerjalan],
      absensiGagal: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Presensi Sekarang'), findsOneWidget);
    expect(find.textContaining('Presensi tercatat'), findsNothing);
  });

  testWidgets('tanpa item berjalan → tidak ada request absensi', (tester) async {
    await pumpDashboard(tester, agendaHariIni: []);

    expect(tester.takeException(), isNull);
    expect(
      _adapter.paths.where((p) => p.contains('/api/v1/absensi/')),
      isEmpty,
      reason: 'cek presensi hanya dipicu item berjalan — agenda kosong '
          'tidak boleh menambah fetch sia-sia',
    );
    expect(find.text('Presensi Sekarang'), findsNothing);
  });
}
