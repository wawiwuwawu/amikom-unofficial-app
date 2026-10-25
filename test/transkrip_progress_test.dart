// Regresi kontrak tiga besaran SKS (BE 68b0955). Backend kini mengirim
// `total_sks_diambil` di 3 endpoint transkrip, dan FE tidak boleh tertukar:
//
//   total_sks_lulus (126, final semester selesai) -> IPK/simulasi/cumlaude
//   sks_sedang_ditempuh (20, berjalan)            -> TIDAK diparse FE
//   total_sks_diambil (146 = 126 + 20)            -> gate kelulusan/progres
//
// Yang dijaga: pill persen (clamp maksimal 100), cabang stats progress
// kelulusan, caption/penjaga beda basis di sheet transkrip, dan bahwa
// simulator target IPK tetap memakai basis nilai final-nya sendiri.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_amikom/models/histori_ipk.dart';
import 'package:app_amikom/models/transkrip.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';
import 'package:app_amikom/widgets/cumlaude_sheet.dart';
import 'package:app_amikom/widgets/histori_ipk_sheet.dart';
import 'package:app_amikom/widgets/progress_kelulusan_card.dart';

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

// ── Fixtures payload API ────────────────────────────────────────────────────

Map<String, dynamic> _progressPayload({
  required int totalSksDiambil,
  int totalSksLulus = 126,
  int targetSks = 144,
  int sisaSks = 0,
  double persentase = 100,
  int estimasiSisaSemester = 0,
}) =>
    {
      'jenjang': 'S1',
      'prodi': 'Informatika',
      'target_sks': targetSks,
      'total_sks_lulus': totalSksLulus,
      'total_sks_diambil': totalSksDiambil,
      'sisa_sks': sisaSks,
      'persentase_kelulusan': persentase,
      'semester_saat_ini': 7,
      'estimasi_sisa_semester': estimasiSisaSemester,
      'kelayakan_akademik_wisuda': {
        'ipk_lulus_eligible': true,
        'ipk_terakhir': 3.62,
        'min_ipk_lulus': 2.5,
        'bebas_nilai_d_e_eligible': true,
        'd_e_matkul_count': 0,
        'd_e_matkul_items': [],
        'warning_wisuda': '',
      },
      'jalur_kelulusan': {
        'skripsi_reguler': {
          'pkl_eligible': true,
          'skripsi_eligible': true,
          'sisa_sks_menuju_skripsi': 0,
        },
        'technopreneur_it': {
          'eligible_sks_ipk': false,
          'sisa_sks_menuju_140': 0,
          'syarat_tambahan': [],
        },
      },
    };

final _cumlaudePayload = {
  'is_cumlaude_eligible': false,
  'predikat_saat_ini': 'Memuaskan',
  'ipk_terakhir': 3.62,
  'total_sks_lulus': 126,
  'total_sks_diambil': 146,
  'semester_saat_ini': 7,
  'analisis_syarat': {
    'syarat_ipk': {
      'is_fulfilled': true,
      'current_val': '3.62',
      'target': '3.60',
      'description': 'IPK memenuhi syarat',
    },
    'syarat_masa_studi': {
      'is_fulfilled': true,
      'current_val': '7 semester',
      'target': '<= 8 semester',
      'description': 'Masa studi memenuhi syarat',
    },
    'syarat_status_masuk': {
      'is_fulfilled': true,
      'current_val': 'Reguler 2024',
      'target': 'Reguler',
      'description': 'Status masuk memenuhi syarat',
    },
    'syarat_nilai_minimum': {
      'is_fulfilled': true,
      'violating_matkul_count': 0,
      'target': 'B-',
      'description': 'Tidak ada nilai di bawah B-',
      'violating_matkul': [],
    },
  },
  'rekomendasi_tindakan': ['Pertahankan IPK di atas 3.60'],
};

final _historiPayload = {
  'ipk_terakhir': 3.62,
  'total_sks_lulus': 126,
  'total_sks_diambil': 146,
  'trend_semester': [
    {
      'semester': 1,
      'tahun_akademik': '2024/2025 - Ganjil',
      'sks_semester': 20,
      'ips': 3.5,
      'ipk_kumulatif': 3.5,
      'delta': 0.0,
    },
  ],
};

// ── Fixtures objek Dart (konstruktor wajib `required`) ──────────────────────

KelayakanWisuda _kelayakanWisuda() => KelayakanWisuda(
      ipkLulusEligible: true,
      ipkTerakhir: 3.62,
      minIpkLulus: 2.5,
      bebasNilaiDEEligible: true,
      dEMatkulCount: 0,
      dEMatkulItems: const [],
      warningWisuda: '',
    );

JalurKelulusan _jalurKelulusan() => JalurKelulusan(
      skripsiReguler: SkripsiRegulerInfo(
        pklEligible: true,
        skripsiEligible: true,
        sisaSksMenujuSkripsi: 0,
      ),
      technopreneurIt: TechnopreneurItInfo(
        eligibleSksIpk: false,
        sisaSksMenuju140: 0,
        syaratTambahan: const [],
      ),
    );

ProgressKelulusanData _progressData({
  int totalSksDiambil = 146,
  int totalSksLulus = 126,
  int targetSks = 144,
  int sisaSks = 0,
  double persentase = 100,
  int estimasiSisaSemester = 0,
}) =>
    ProgressKelulusanData(
      jenjang: 'S1',
      prodi: 'Informatika',
      targetSks: targetSks,
      totalSksLulus: totalSksLulus,
      totalSksDiambil: totalSksDiambil,
      sisaSks: sisaSks,
      persentaseKelulusan: persentase,
      semesterSaatIni: 7,
      estimasiSisaSemester: estimasiSisaSemester,
      kelayakanAkademikWisuda: _kelayakanWisuda(),
      jalurKelulusan: _jalurKelulusan(),
    );

SyaratDetail _syaratDetail() => SyaratDetail(
      isFulfilled: true,
      currentVal: '3.62',
      target: '3.60',
      description: 'Syarat terpenuhi',
    );

CumlaudeData _cumlaudeData() => CumlaudeData(
      isCumlaudeEligible: false,
      predikatSaatIni: 'Memuaskan',
      ipkTerakhir: 3.62,
      totalSksLulus: 126,
      totalSksDiambil: 146,
      semesterSaatIni: 7,
      analisisSyarat: AnalisisSyarat(
        syaratIpk: _syaratDetail(),
        syaratMasaStudi: _syaratDetail(),
        syaratStatusMasuk: _syaratDetail(),
        syaratNilaiMinimum: SyaratNilaiMinimumDetail(
          isFulfilled: true,
          violatingMatkulCount: 0,
          target: 'B-',
          description: 'Tidak ada nilai di bawah B-',
          violatingMatkul: const [],
        ),
      ),
      rekomendasiTindakan: const ['Pertahankan IPK di atas 3.60'],
    );

void main() {
  setUpAll(() {
    // ApiClient membaca API_BASE_URL dari dotenv saat instance pertama dibuat.
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  Future<void> pumpCard(WidgetTester tester, ProgressKelulusanData data) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ProgressKelulusanCard(data: data),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpHistoriSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: HistoriIpkSheet()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  // ── 1. Parsing model ──────────────────────────────────────────────────────

  group('ProgressKelulusanData.fromJson total_sks_diambil', () {
    test('memetakan total_sks_diambil dari payload', () {
      final data = ProgressKelulusanData.fromJson(
        _progressPayload(totalSksDiambil: 146),
      );

      expect(data.totalSksDiambil, equals(146));
      expect(data.totalSksLulus, equals(126));
      expect(data.targetSks, equals(144));
      expect(data.sisaSks, equals(0));
    });

    test('tanpa total_sks_diambil jatuh ke 0, field lama tetap ter-parse', () {
      final json = _progressPayload(totalSksDiambil: 146)
        ..remove('total_sks_diambil');
      final data = ProgressKelulusanData.fromJson(json);

      expect(data.totalSksDiambil, equals(0));
      expect(data.totalSksLulus, equals(126));
      expect(data.targetSks, equals(144));
    });
  });

  group('CumlaudeData.fromJson total_sks_diambil', () {
    test('memetakan total_sks_diambil dari payload', () {
      final data = CumlaudeData.fromJson(_cumlaudePayload);

      expect(data.totalSksDiambil, equals(146));
      expect(data.totalSksLulus, equals(126));
      expect(data.semesterSaatIni, equals(7));
    });

    test('tanpa total_sks_diambil jatuh ke 0, field lama tetap ter-parse', () {
      final json = Map<String, dynamic>.from(_cumlaudePayload)
        ..remove('total_sks_diambil');
      final data = CumlaudeData.fromJson(json);

      expect(data.totalSksDiambil, equals(0));
      expect(data.totalSksLulus, equals(126));
    });
  });

  group('HistoriIpkData.fromJson total_sks_diambil', () {
    test('memetakan total_sks_diambil dari payload', () {
      final data = HistoriIpkData.fromJson(_historiPayload);

      expect(data.totalSksDiambil, equals(146));
      expect(data.totalSksLulus, equals(126));
      expect(data.trendSemester.length, equals(1));
    });

    test('tanpa total_sks_diambil jatuh ke 0, field lama tetap ter-parse', () {
      final json = Map<String, dynamic>.from(_historiPayload)
        ..remove('total_sks_diambil');
      final data = HistoriIpkData.fromJson(json);

      expect(data.totalSksDiambil, equals(0));
      expect(data.totalSksLulus, equals(126));
      expect(data.trendSemester.length, equals(1));
    });
  });

  // ── 2. Kartu progres kelulusan: lulus ─────────────────────────────────────

  testWidgets('progress penuh tampil SKS terpenuhi + rincian berjalan',
      (tester) async {
    await pumpCard(
      tester,
      _progressData(sisaSks: 0, totalSksDiambil: 146, persentase: 100),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('100% (146/144)'), findsOneWidget);
    expect(find.text('SKS terpenuhi'), findsOneWidget);
    expect(find.text('126 final • 20 berjalan'), findsOneWidget);
    expect(find.textContaining('Sisa'), findsNothing);
    expect(find.text('146 / 144 SKS Terkumpul'), findsNothing);
  });

  // ── 3. Kartu progres kelulusan: belum lulus ───────────────────────────────

  testWidgets('progress belum penuh tampil Sisa belum diambil', (tester) async {
    // Angka konsisten dengan cabang belum: SKS diambil masih di bawah target
    // (146/144 akan selalu masuk cabang sukses karena gate memakai diambil).
    await pumpCard(
      tester,
      _progressData(
        sisaSks: 4,
        estimasiSisaSemester: 1,
        totalSksDiambil: 140,
        targetSks: 144,
        totalSksLulus: 126,
        persentase: 97.2,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('97% (140/144)'), findsOneWidget);
    expect(find.text('140 / 144 SKS Terkumpul'), findsOneWidget);
    expect(find.text('Sisa 4 SKS belum diambil • ~1 Smt Lg'), findsOneWidget);
    expect(find.text('SKS terpenuhi'), findsNothing);
    expect(find.textContaining('berjalan'), findsNothing);
  });

  testWidgets('pill persen diklamp maksimal 100 walau backend kirim 101.4',
      (tester) async {
    await pumpCard(
      tester,
      _progressData(sisaSks: 0, totalSksDiambil: 146, persentase: 101.4),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('100% (146/144)'), findsOneWidget);
    expect(find.text('101% (146/144)'), findsNothing);
  });

  testWidgets('gate memakai total_sks_diambil walau sisa_sks belum sinkron',
      (tester) async {
    // Backend mengirim sisa_sks 4 padahal SKS diambil sudah >= target: gate FE
    // tetap kompak dengan kontrak baru (diambil, bukan sisa).
    await pumpCard(
      tester,
      _progressData(sisaSks: 4, totalSksDiambil: 146, persentase: 98.6),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('SKS terpenuhi'), findsOneWidget);
    expect(find.textContaining('126 final'), findsOneWidget);
    expect(find.textContaining('Sisa'), findsNothing);
  });

  // ── 4. Sheet cumlaude ────────────────────────────────────────────────────

  testWidgets('sheet cumlaude memakai SKS terkumpul + caption dasar penilaian',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: CumlaudeSheet(data: _cumlaudeData())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('146 SKS'), findsOneWidget);
    expect(find.text('SKS Terkumpul'), findsOneWidget);
    expect(
      find.text(
        'Dasar penilaian cumlaude: 126 SKS lulus final • 20 SKS berjalan',
      ),
      findsOneWidget,
    );
    expect(find.text('SKS Lulus'), findsNothing);
  });

  // ── 5. Sheet histori IPK (lewat Dio palsu) ───────────────────────────────

  testWidgets('sheet histori IPK memakai SKS terkumpul + caption basis final',
      (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(_historiPayload);

    await pumpHistoriSheet(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('146 SKS'), findsOneWidget);
    expect(find.text('SKS Terkumpul'), findsOneWidget);
    expect(
      find.text(
        'IPK & grafik memakai 126 SKS final; 20 SKS berjalan belum masuk hitungan',
      ),
      findsOneWidget,
    );
  });

  // ── 6. Layar sempit 360x640 ──────────────────────────────────────────────

  testWidgets('kartu progres aman di layar 360x640 tanpa overflow',
      (tester) async {
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    await tester.binding.setSurfaceSize(const Size(360, 640));

    await pumpCard(
      tester,
      _progressData(sisaSks: 0, totalSksDiambil: 146, persentase: 101.4),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('100% (146/144)'), findsOneWidget);
    expect(find.text('SKS terpenuhi'), findsOneWidget);
    expect(find.text('126 final • 20 berjalan'), findsOneWidget);
    expect(find.byType(FittedBox), findsOneWidget);
  });
}
