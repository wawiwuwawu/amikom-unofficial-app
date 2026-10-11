// Regresi Fase A "Absensi & Auto-Validasi" (jadwal/agenda):
//   • `AgendaItem` mem-parsing `jam_mulai`/`jam_selesai` baru dan tetap aman
//     pada respons lama yang tidak mengirim field itu.
//   • `dayValue` menaruh bucket "Lainnya" (8) & "Tanpa Jadwal" (9) di bawah
//     hari biasa (Senin = 1 … Minggu = 7).
//   • Deteksi "Sedang berlangsung" di beranda memakai `jamMulai`/`jamSelesai`
//     bila ada, jatuh ke parsing `jam` lama bila tidak, dan TIDAK pernah
//     menandai item tanpa jam (mis. bucket "Tanpa Jadwal") sebagai berlangsung.
// Pola adapter Dio palsu mengikuti test/asisten_page_layout_test.dart.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_amikom/models/agenda_terpadu.dart';
import 'package:app_amikom/pages/dashboard_page.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/utils/format.dart';

const _dashboardPath = '/api/v1/dashboard';
const _agendaPath = '/api/v1/agenda/terpadu';
const _spPath = '/api/v1/sp/rekomendasi';

/// Adapter Dio palsu: peta respons bisa diganti antar kasus uji.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._responses);

  final Map<String, Map<String, dynamic>> _responses;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body =
        _responses[options.path] ?? {'status': 'success', 'data': null};
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  group('AgendaItem', () {
    test('mem-parsing jam_mulai/jam_selesai', () {
      final item = AgendaItem.fromJson(const {
        'tipe': 'kuliah',
        'hari': 'Senin',
        'jam': '10:40 - 12:20',
        'jam_mulai': '10:40',
        'jam_selesai': '12:20',
        'ruang': 'D.1.1',
        'matakuliah': 'Pemrograman Mobile',
        'detail': 'Pak Budi',
      });

      expect(item.jamMulai, '10:40');
      expect(item.jamSelesai, '12:20');
      expect(item.jam, '10:40 - 12:20');
    });

    test('respons lama tanpa jam_mulai/jam_selesai tetap aman', () {
      final item = AgendaItem.fromJson(const {
        'tipe': 'kuliah',
        'hari': 'Senin',
        'jam': '10:40 - 12:20',
        'ruang': 'D.1.1',
        'matakuliah': 'Pemrograman Mobile',
        'detail': 'Pak Budi',
      });

      expect(item.jamMulai, '');
      expect(item.jamSelesai, '');
      expect(item.jam, '10:40 - 12:20');
    });

    test('bucket "Tanpa Jadwal" ikut ter-parse pada peta agenda', () {
      final data = AgendaTerpaduData.fromJson(const {
        'total_agenda': 2,
        'agenda': {
          'Senin': [
            {
              'tipe': 'kuliah',
              'hari': 'Senin',
              'jam': '10:40 - 12:20',
              'ruang': 'D.1.1',
              'matakuliah': 'Pemrograman Mobile',
              'detail': 'Pak Budi',
            },
          ],
          'Tanpa Jadwal': [
            {
              'tipe': 'kuliah',
              'hari': '',
              'jam': '',
              'ruang': '',
              'matakuliah': 'Skripsi',
              'detail': '',
            },
          ],
        },
      });

      expect(data.totalAgenda, 2);
      expect(data.agenda.keys, containsAll(['Senin', 'Tanpa Jadwal']));
      expect(data.agenda['Tanpa Jadwal']!.single.matakuliah, 'Skripsi');
      expect(data.agenda['Tanpa Jadwal']!.single.jamMulai, '');
      expect(data.agenda['Senin']!.single.jamSelesai, '');
    });
  });

  group('dayValue', () {
    test('"Tanpa Jadwal" di bawah "Lainnya", keduanya di bawah hari biasa', () {
      expect(dayValue('Minggu'), 7);
      expect(dayValue("Jum'at"), 5);
      expect(dayValue('minggu'), 7);
      expect(dayValue('  Sabtu  '), 6);
      expect(dayValue('Lainnya'), greaterThan(dayValue('Minggu')));
      expect(dayValue('Tanpa Jadwal'), greaterThan(dayValue('Lainnya')));
    });

    test('label seksi: hanya bucket khusus yang diterjemahkan', () {
      expect(agendaDayLabel('Tanpa Jadwal'), 'Belum ada jadwal');
      expect(agendaDayLabel('tanpa jadwal'), 'Belum ada jadwal');
      expect(agendaDayLabel('Senin'), 'Senin');
    });
  });

  group('Beranda — jadwal hari ini', () {
    // Nama hari ini harus sama dengan `_getHariIndo` di dashboard_page.dart,
    // karena hanya bucket hari itulah yang diperiksa `_ongoingItem`.
    final today = _hariIni();

    // Jendela yang selalu memuat "sekarang" (diklem ke rentang harian 00:00
    // – 23:59 supaya aman di dekat tengah malam).
    final mulai = _hhmm(_nowMins() - 60);
    final selesai = _hhmm(_nowMins() + 60);

    testWidgets('jam_mulai/jam_selesai yang mencakup sekarang = berlangsung',
        (tester) async {
      await _pumpDashboard(tester, {
        today: [
          {
            'tipe': 'kuliah',
            'hari': today,
            // Jam tampilan sengaja TIDAK mencakup sekarang — yang menang
            // harus jam_mulai/jam_selesai.
            'jam': '08:00 - 09:40',
            'jam_mulai': mulai,
            'jam_selesai': selesai,
            'ruang': 'D.1.1',
            'matakuliah': 'Jaringan Komputer',
            'detail': 'Pak Budi',
          },
        ],
      });

      expect(tester.takeException(), isNull);
      expect(find.text('Sedang berlangsung'), findsOneWidget);
      expect(find.text('Berlangsung'), findsOneWidget);
      expect(find.text('Jaringan Komputer'), findsWidgets);
    });

    testWidgets('respons lama: parsing jam "hh:mm - hh:mm" tetap berfungsi',
        (tester) async {
      await _pumpDashboard(tester, {
        today: [
          {
            'tipe': 'kuliah',
            'hari': today,
            'jam': '$mulai - $selesai',
            'ruang': 'D.1.1',
            'matakuliah': 'Basis Data',
            'detail': 'Bu Sari',
          },
        ],
      });

      expect(tester.takeException(), isNull);
      expect(find.text('Sedang berlangsung'), findsOneWidget);
      expect(find.text('Basis Data'), findsWidgets);
    });

    testWidgets('item tanpa jam dan jam tanpa tanda "-" tak pernah berlangsung',
        (tester) async {
      await _pumpDashboard(tester, {
        today: [
          {
            'tipe': 'kuliah',
            'hari': today,
            'jam': '12:30:00', // tanpa '-' → tak bisa jadi rentang
            'ruang': 'D.1.2',
            'matakuliah': 'Praktikum Jaringan',
            'detail': '',
          },
          {
            'tipe': 'kuliah',
            'hari': today,
            'jam': '', // tanpa jam sama sekali ( gaya bucket "Tanpa Jadwal")
            'ruang': '',
            'matakuliah': 'Skripsi',
            'detail': '',
          },
        ],
        'Tanpa Jadwal': [
          {
            'tipe': 'kuliah',
            'hari': '',
            'jam': '',
            'ruang': '',
            'matakuliah': 'Skripsi Tanpa Jadwal',
            'detail': '',
          },
        ],
      });

      expect(tester.takeException(), isNull);
      expect(find.text('Sedang berlangsung'), findsNothing);
      expect(find.text('Berlangsung'), findsNothing);
      // Baris tetap dirender walau tak ada yang berlangsung.
      expect(find.text('Praktikum Jaringan'), findsOneWidget);
      expect(find.text('Skripsi'), findsOneWidget);
    });
  });
}

// ── Pembantu ─────────────────────────────────────────────────────────────────

/// Nama hari ini dalam bahasa Indonesia — mencerminkan `_getHariIndo`
/// (_DashboardPageState) yang menentukan bucket agenda yang diperiksa.
String _hariIni() {
  const names = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  return names[DateTime.now().weekday - 1];
}

int _nowMins() => DateTime.now().hour * 60 + DateTime.now().minute;

int _clampMins(int mins) => mins < 0 ? 0 : (mins > 1439 ? 1439 : mins);

String _hhmm(int mins) {
  final clamped = _clampMins(mins);
  final h = (clamped ~/ 60).toString().padLeft(2, '0');
  final m = (clamped % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

Map<String, Map<String, dynamic>> _responses(
  Map<String, List<Map<String, dynamic>>> agenda,
) {
  final total = agenda.values.fold<int>(0, (sum, items) => sum + items.length);
  return {
    _dashboardPath: {
      'status': 'success',
      'data': {'profile': {}, 'statistik': {}, 'status': {}},
    },
    _agendaPath: {
      'status': 'success',
      'data': {'total_agenda': total, 'agenda': agenda},
    },
    _spPath: {'status': 'success', 'data': {}},
  };
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  Map<String, List<Map<String, dynamic>>> agenda,
) async {
  ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_responses(agenda));

  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: const DashboardPage()),
  );
  // Beranda memakai animasi fadeIn (flutter_animate) — pumpAndSettle
  // menguras timer/animasi agar tak ada Timer pending saat tes berakhir.
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}
