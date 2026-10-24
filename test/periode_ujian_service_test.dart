// Test PeriodeUjianService: pilih ujian terdekat yang belum lewat, skip
// tanggal tak terbaca, fail-open saat fetch gagal, memoize per sesi (TTL)
// dengan reset untuk test, dan gerbang jendela tampil [dalamJendela].
// Seluruh request jaringan lewat adapter Dio palsu — tidak ada Firebase.

import 'dart:convert';
import 'dart:typed_data';

import 'package:app_amikom/models/jadwal_ujian.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/periode_ujian_service.dart';
import 'package:app_amikom/utils/waktu.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _hariIni() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _ddmmyyyy(DateTime t) {
  final d = t.day.toString().padLeft(2, '0');
  final m = t.month.toString().padLeft(2, '0');
  return '$d-$m-${t.year}';
}

Map<String, dynamic> _baris({
  String? tanggal,
  String mkl = 'Basis Data',
}) =>
    {
      'KODE': 'TIF123',
      'MKL': mkl,
      'TANGGAL': ?tanggal,
      'HARI': 'Selasa',
      'RUANG': 'D.1.1',
      'JAM_MULAI': '07:30',
      'JAM_SELESEI': '09:10',
      'NOKURSI': 5,
    };

/// Adapter jadwal-ujian: membalas GET /api/v1/akademik/jadwal-ujian
/// (?jenis=uts|uas) dengan [uts]/[uas]; null berarti fetch gagal.
/// Endpoint lain selalu gagal (tidak dipakai layanan ini).
class _UjianAdapter implements HttpClientAdapter {
  _UjianAdapter({this.uts, this.uas});

  List<Map<String, dynamic>>? uts;
  List<Map<String, dynamic>>? uas;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    if (options.path.contains('/api/v1/akademik/jadwal-ujian')) {
      final rows = options.queryParameters['jenis'] == 'uas' ? uas : uts;
      if (rows == null) throw Exception('simulasi offline');
      return ResponseBody.fromString(
        jsonEncode({'status': 'success', 'data': rows}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    throw Exception('endpoint tak dikenal');
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  late _UjianAdapter adapter;

  setUp(() {
    adapter = _UjianAdapter(uts: [], uas: []);
    ApiClient.instance.dio.httpClientAdapter = adapter;
    PeriodeUjianService.instance.resetUntukTest();
  });

  group('tanggalUjianTerdekat (service, fail-open + memoize)', () {
    test('pilih ujian terdekat yang belum lewat dari uts & uas', () async {
      adapter.uts = [_baris(tanggal: _ddmmyyyy(_hariIni().add(const Duration(days: 10))))];
      adapter.uas = [_baris(tanggal: _ddmmyyyy(_hariIni().add(const Duration(days: 3))))];

      final hasil = await PeriodeUjianService.instance.tanggalUjianTerdekat();

      expect(hasil, isNotNull);
      expect(hasil!.$1, _hariIni().add(const Duration(days: 3)));
      expect(hasil.$2, 'UAS');
    });

    test('ujian yang sudah lewat diskip; tanpa ujian mendatang → null', () async {
      adapter.uts = [
        _baris(tanggal: _ddmmyyyy(_hariIni().subtract(const Duration(days: 2)))),
      ];

      final hasil = await PeriodeUjianService.instance.tanggalUjianTerdekat();

      expect(hasil, isNull, reason: 'semua ujian sudah lewat → null, bukan galat');
    });

    test('tanggal tak terbaca dilewati', () async {
      adapter.uts = [_baris(tanggal: 'belum diumumkan')];
      adapter.uas = [_baris(tanggal: _ddmmyyyy(_hariIni().add(const Duration(days: 2))))];

      final hasil = await PeriodeUjianService.instance.tanggalUjianTerdekat();

      expect(hasil!.$2, 'UAS');
    });

    test('fetch gagal → null (fail-open, tidak melempar)', () async {
      adapter.uts = null; // keduanya gagal
      adapter.uas = null;

      final hasil = PeriodeUjianService.instance.tanggalUjianTerdekat();

      // Tidak melempar — hasil null.
      expect(await hasil, isNull);
    });

    test('memoize per sesi: panggilan berulang tidak meng-hammer endpoint',
        () async {
      adapter.uts = [_baris(tanggal: _ddmmyyyy(_hariIni().add(const Duration(days: 3))))];
      adapter.uas = [];

      await PeriodeUjianService.instance.tanggalUjianTerdekat();
      await PeriodeUjianService.instance.tanggalUjianTerdekat();
      await PeriodeUjianService.instance.tanggalUjianTerdekat();

      // 2 request (uts + uas) hanya pada panggilan pertama.
      expect(adapter.requests, 2);
    });

    test('hasil gagal juga dimemoize (TTL 5 menit), reset untuk test memuat ulang',
        () async {
      adapter.uts = null;
      adapter.uas = null;

      await PeriodeUjianService.instance.tanggalUjianTerdekat();
      await PeriodeUjianService.instance.tanggalUjianTerdekat();
      expect(adapter.requests, 2, reason: 'hasil gagal dimemoize');

      adapter.uts = [_baris(tanggal: _ddmmyyyy(_hariIni().add(const Duration(days: 3))))];
      adapter.uas = [];
      PeriodeUjianService.instance.resetUntukTest();

      final hasil = await PeriodeUjianService.instance.tanggalUjianTerdekat();
      expect(hasil, isNotNull, reason: 'setelah reset, data baru dimuat');
      expect(adapter.requests, 4);
    });
  });

  group('pilihTerdekat (pure)', () {
    test('tanggal minimum ≥ hari ini menang, UTS vs UAS', () {
      final hari = _hariIni();
      final barisUts = JadwalUjian.fromJson(
        _baris(tanggal: _ddmmyyyy(hari.add(const Duration(days: 9)))),
      );
      final barisUas = JadwalUjian.fromJson(
        _baris(tanggal: _ddmmyyyy(hari.add(const Duration(days: 9)))),
      );
      final hasil = PeriodeUjianService.pilihTerdekat(
        [barisUts],
        [barisUas],
        hari,
      );
      expect(hasil!.$2, 'UTS', reason: 'urutan sama → yang pertama dipertahankan');
    });

    test('semua baris lewat / tanggal kosong → null', () {
      final hari = _hariIni();
      final hasil = PeriodeUjianService.pilihTerdekat(
        [
          JadwalUjian.fromJson(
            _baris(tanggal: _ddmmyyyy(hari.subtract(const Duration(days: 1)))),
          ),
          JadwalUjian.fromJson(_baris(tanggal: '')),
        ],
        [],
        hari,
      );
      expect(hasil, isNull);
    });
  });

  group('dalamJendela (gerbang tampil)', () {
    test('periode null → fail-open (tampil)', () {
      expect(PeriodeUjianService.dalamJendela(null, _hariIni()), isTrue);
    });

    test('hari ini dan dalam ambang 7 hari → tampil', () {
      final hari = _hariIni();
      expect(
        PeriodeUjianService.dalamJendela((hari, 'UTS'), hari),
        isTrue,
      );
      expect(
        PeriodeUjianService.dalamJendela(
          (hari.add(const Duration(days: 6)), 'UTS'),
          hari,
        ),
        isTrue,
      );
    });

    test('lewat dari ambang / sudah lewat → tidak tampil', () {
      final hari = _hariIni();
      expect(
        PeriodeUjianService.dalamJendela(
          (hari.add(const Duration(days: 7)), 'UTS'),
          hari,
        ),
        isFalse,
      );
      expect(
        PeriodeUjianService.dalamJendela(
          (hari.subtract(const Duration(days: 1)), 'UTS'),
          hari,
        ),
        isFalse,
      );
    });
  });

  group('helper waktu (sumber tunggal parser dd-MM-yyyy)', () {
    test('tanggalDariDdMmYyyy valid', () {
      expect(tanggalDariDdMmYyyy('08-07-2026'), DateTime(2026, 7, 8));
    });

    test('tanggal tidak valid / format lain → null', () {
      expect(tanggalDariDdMmYyyy(''), isNull);
      expect(tanggalDariDdMmYyyy('32-13-2026'), isNull);
      expect(tanggalDariDdMmYyyy('2026-07-08'), isNull);
      expect(tanggalDariDdMmYyyy('abc'), isNull);
    });

    test('formatTanggalIndo memakai nama bulan Indonesia', () {
      expect(formatTanggalIndo(DateTime(2026, 11, 24)), '24 November 2026');
    });
  });
}
