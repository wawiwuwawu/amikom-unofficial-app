// Regresi kontrak Fase B absensi (manual asdos×kriteria + auto-validasi).
//
// Berkas ini sengaja ditulis "fail-before": terhadap kode lama,
//  * `asdospenilaian` berkey `{kriteriaId}` tunggal (tanpa indeks asdos) dan
//    `asdos_npms` selalu kosong — praktikum multi-asdos gagal total;
//  * `jenispilih` ditebak dari keterangan, `kuliahteori` selalu `kuliah_tp_id`;
//  * `autoValidasi` belum ada, dan `unwrapData` menelan envelope galat
//    ({status:'error'} / data.success:false) sebagai hasil nol — dialog
//    bohong yang bilang sukses.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_amikom/models/absensi.dart';
import 'package:app_amikom/models/absensi_validasi.dart';
import 'package:app_amikom/models/app_failure.dart';
import 'package:app_amikom/pages/absensi_detail_page.dart';
import 'package:app_amikom/services/absensi_service.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/theme/app_theme.dart';

/// Adapter Dio palsu: balas payload per alamat dan tangkap body POST.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._responseFor, {this.captured});

  final Map<String, dynamic> Function(String path) _responseFor;
  final void Function(Map<String, dynamic> body)? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      final raw = utf8.decode(bytes);
      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) captured?.call(decoded);
      }
    }
    return ResponseBody.fromString(
      jsonEncode(_responseFor(options.path)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Detail presensi praktikum dengan 2 asdos, masing-masing 1 kriteria
/// bernilai '1' dengan dua pilihan nilai ('10' nilai 1, '11' nilai 4).
Map<String, dynamic> _presensiPayload({
  List<dynamic>? asdoss,
  List<dynamic>? kriterias,
}) => {
      'status': 'success',
      'data': {
        'nik': '102938',
        'nama': 'Budi Santoso',
        'tanggal': 'Senin, 7 September 2026',
        'judul_materi': 'Praktikum Layout Flutter',
        'id_presensi_mhs': '5123',
        'id_presensi_dosen': '8842',
        'keterangan': 'B',
        'jam': '08:00 - 10:00',
        'validasi': null,
        'kuliah_tp_id': '5566',
        'kriterias': kriterias ?? <dynamic>[],
        'asdoss': asdoss ?? [_asdos('21SA1001', 'Dede Saputra'), _asdos('21SA1002', 'Rina Wati')],
      },
    };

Map<String, dynamic> _kriteria(String id) => {
      'asdos_krit_id': id,
      'asdos_krit_isi': 'Kesesuaian materi',
      'nilai': [
        {
          'asdos_krit_nilai_id': '${id}0',
          'asdos_krit_nilai_isi': 'Kurang',
          'asdos_krit_nilai': 1,
        },
        {
          'asdos_krit_nilai_id': '${id}1',
          'asdos_krit_nilai_isi': 'Baik',
          'asdos_krit_nilai': 4,
        },
      ],
    };

Map<String, dynamic> _asdos(String npm, String nama) => {
      'npm': npm,
      'nama': nama,
      'kriterias': [_kriteria('1')],
    };

const _autoValidasiPayload = {
  'status': 'success',
  'data': {
    'ringkasan': {
      'total': 3,
      'sukses': 1,
      'gagal': 1,
      'dilewati': 1,
      'dry_run': false,
    },
    'pertemuan': [
      {
        'makul': 'Pemrograman Mobile',
        'id_presensi_dosen': '9001',
        'id_presensi_mhs': '7001',
        'jenis': 'praktek',
        'jumlah_asdos': 3,
        'status': 'sukses',
        'alasan': '',
        'payload': {'mode': 'tulis', 'pendekatan': 'wajar'},
      },
      {
        'makul': 'Basis Data',
        'id_presensi_dosen': '9002',
        'id_presensi_mhs': '7002',
        'jenis': 'teori',
        'jumlah_asdos': 0,
        'status': 'gagal',
        'alasan': 'Portal menolak: nilai asdos belum lengkap',
        'payload': {},
      },
      {
        'makul': 'Jaringan Komputer',
        'id_presensi_dosen': '9003',
        'id_presensi_mhs': '7003',
        'jenis': 'teori',
        'jumlah_asdos': 0,
        'status': 'dilewati',
        'alasan': 'Sudah divalidasi',
        'payload': {},
      },
    ],
  },
};

RiwayatPertemuan _pertemuanB() => RiwayatPertemuan.fromJson({
      'tanggal': 'Senin, 7 September 2026',
      'materi': 'Praktikum Layout Flutter',
      'status': 'B',
      'jenis': 'praktek',
      'id_kuliah_teori': '5566',
      'id_kuliah_praktek': '7788',
    });

/// Rantai async (adapter palsu) butuh beberapa frame untuk selesai.
Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 25));
  }
}

AbsensiDetailPage _page({RiwayatPertemuan? pertemuan}) => AbsensiDetailPage(
      idPresensi: '77',
      pertemuan: pertemuan,
    );

/// Meniru navigasi asli (halaman daftar → detail): detail selalu didorong di
/// atas rute lain, sehingga `Navigator.pop` setelah submit sukses aman.
class _Launcher extends StatefulWidget {
  const _Launcher({required this.child});

  final Widget child;

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => widget.child),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  group('model', () {
    test('RiwayatPertemuan membawa jenis & id kuliah pertemuan B', () {
      final b = RiwayatPertemuan.fromJson({
        'status': 'B',
        'jenis': 'praktek',
        'id_kuliah_teori': '5566',
        'id_kuliah_praktek': 7788,
      });
      expect(b.jenis, 'praktek');
      expect(b.idKuliahTeori, '5566');
      // Angka pun ikut dinormalkan jadi String.
      expect(b.idKuliahPraktek, '7788');

      // Respons lama tanpa field baru tetap aman (null, bukan crash).
      final lama = RiwayatPertemuan.fromJson({'status': 'H'});
      expect(lama.jenis, isNull);
      expect(lama.idKuliahTeori, isNull);
      expect(lama.idKuliahPraktek, isNull);
    });

    test('PresensiDetail mem-parse asdoss beserta kriteria tiap asdos', () {
      final detail = PresensiDetail.fromJson(_presensiPayload()['data']
          as Map<String, dynamic>);
      expect(detail.asdoss, hasLength(2));
      expect(detail.asdoss.first.npm, '21SA1001');
      expect(detail.asdoss.first.nama, 'Dede Saputra');
      expect(detail.asdoss.first.kriterias.single.id, '1');
      expect(detail.asdoss[1].kriterias.single.nilai, hasLength(2));
      expect(detail.asdoss[1].kriterias.single.nilai.first.id, '10');
    });

    test('Asdos tanpa nama/kriteria tidak melempar', () {
      final a = Asdos.fromJson({'npm': '21SA1'});
      expect(a.npm, '21SA1');
      expect(a.nama, '');
      expect(a.kriterias, isEmpty);
    });

    test('AutoValidasiRingkasan aman untuk angka string/double', () {
      final r = AutoValidasiRingkasan.fromJson({
        'total': '3',
        'sukses': 1.0,
        'gagal': null,
        'dilewati': 0,
        'dry_run': 'true',
      });
      expect(r.total, 3);
      expect(r.sukses, 1);
      expect(r.gagal, 0);
      expect(r.dilewati, 0);
      // Bukan boolean `true` → dryRun false.
      expect(r.dryRun, isFalse);
    });

    test('AutoValidasiMode.wire dikirim apa adanya', () {
      expect(AutoValidasiMode.inspeksi.wire, 'inspeksi');
      expect(AutoValidasiMode.tulis.wire, 'tulis');
    });
  });

  group('AbsensiService.autoValidasi', () {
    test('mem-parse ringkasan & 3 pertemuan sukses/gagal/dilewati', () async {
      final sent = <Map<String, dynamic>>[];
      ApiClient.instance.dio.httpClientAdapter =
          _FakeAdapter((_) => _autoValidasiPayload, captured: sent.add);

      final result =
          await AbsensiService().autoValidasi(AutoValidasiMode.tulis);

      expect(sent.single['mode'], 'tulis');
      expect(sent.single['preset'], 'wajar');

      expect(result.ringkasan.total, 3);
      expect(result.ringkasan.sukses, 1);
      expect(result.ringkasan.gagal, 1);
      expect(result.ringkasan.dilewati, 1);
      expect(result.ringkasan.dryRun, isFalse);

      expect(result.pertemuan, hasLength(3));
      expect(result.pertemuan.map((p) => p.status),
          ['sukses', 'gagal', 'dilewati']);
      expect(result.pertemuan.first.makul, 'Pemrograman Mobile');
      expect(result.pertemuan.first.idPresensiDosen, '9001');
      expect(result.pertemuan.first.idPresensiMhs, '7001');
      expect(result.pertemuan.first.jenis, 'praktek');
      expect(result.pertemuan.first.jumlahAsdos, 3);
      expect(result.pertemuan.first.alasan, '');
      // payload dipetakan (disimpan model), tetap tersedia dari portal.
      expect(result.pertemuan.first.payload['mode'], 'tulis');
      expect(result.pertemuan[1].alasan, 'Portal menolak: nilai asdos belum lengkap');
      // 'dilewati' bukannya galat — hasil tetap jadi.
      expect(result.pertemuan[2].status, 'dilewati');
    });

    test('envelope {status:error} melempar AppFailure, bukan hasil nol',
        () async {
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter((_) => {
            'status': 'error',
            'message': 'Presensi praktikum belum dibuka',
          });

      Object? caught;
      try {
        await AbsensiService()
            .autoValidasi(AutoValidasiMode.inspeksi, preset: 'wajar');
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<AppFailure>());
      expect((caught as AppFailure).message, 'Presensi praktikum belum dibuka');
    });

    test('data.success:false bersarang juga melempar AppFailure', () async {
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter((_) => {
            'status': 'success',
            'data': {
              'success': false,
              'message': 'Asdos belum mengisi nilai',
            },
          });

      Object? caught;
      try {
        await AbsensiService().autoValidasi(AutoValidasiMode.tulis);
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<AppFailure>());
      expect((caught as AppFailure).message, 'Asdos belum mengisi nilai');
    });
  });

  group('AbsensiDetailPage form validasi', () {
    testWidgets('asdos×kriteria: key "{indeks}_{kriteria}" & asdos_npms urut',
        (tester) async {
      final captured = <Map<String, dynamic>>[];
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(
        (path) => path == '/api/v1/absensi/validasi'
            ? const {'status': 'success', 'data': {'success': true}}
            : _presensiPayload(),
        captured: captured.add,
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: _Launcher(child: _page(pertemuan: _pertemuanB())),
      ));
      await _flush(tester);
      expect(find.text('FORM VALIDASI'), findsOneWidget,
          reason: 'form validasi belum termuat setelah detail presensi');

      await tester.ensureVisible(find.text('Validasi Presensi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validasi Presensi'));
      await _flush(tester);

      expect(captured, isNotEmpty,
          reason: 'request validasi tidak terhasil dikirim');
      final body = captured.last;

      // Field pertemuan 'B' dipakai apa adanya, tidak ditebak lagi.
      expect(body['jenispilih'], 'praktek');
      expect(body['kuliahteori'], '5566');
      expect(body['kuliahpraktek'], '7788');
      expect(body['idpresensimhstexs'], '5123');
      expect(body['idpresensidosen'], '8842');

      // NPM mengikuti urutan indeks key penilaian.
      expect(body['asdos_npms'], ['21SA1001', '21SA1002']);
      final penilaian = body['asdospenilaian'] as Map<String, dynamic>;
      expect(penilaian.keys.toSet(), {'0_1', '1_1'});
      // Default = opsi nilai tertinggi tiap kriteria (nilai 4 → id '11').
      expect(penilaian['0_1'], '11');
      expect(penilaian['1_1'], '11');

      // Biarkan SnackBar selesai agar tidak ada timer menggantung.
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('tanpa pertemuan: fallback teori + kuliah_tp_id & tanpa asdos',
        (tester) async {
      final captured = <Map<String, dynamic>>[];
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(
        (path) => path == '/api/v1/absensi/validasi'
            ? const {'status': 'success', 'data': {'success': true}}
            : _presensiPayload(),
        captured: captured.add,
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: _Launcher(child: _page()),
      ));
      await _flush(tester);
      expect(find.text('FORM VALIDASI'), findsOneWidget,
          reason: 'form validasi belum termuat setelah detail presensi');

      await tester.ensureVisible(find.text('Validasi Presensi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validasi Presensi'));
      await _flush(tester);

      expect(captured, isNotEmpty);
      final body = captured.last;
      expect(body['jenispilih'], 'teori');
      expect(body['kuliahteori'], '5566');
      expect(body['kuliahpraktek'], '0');
      // Biarkan SnackBar selesai agar tidak ada timer menggantung.
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('non-asdos: kriterias tingkat atas tetap satu indeks konsisten',
        (tester) async {
      final captured = <Map<String, dynamic>>[];
      ApiClient.instance.dio.httpClientAdapter = _FakeAdapter(
        (path) => path == '/api/v1/absensi/validasi'
            ? const {'status': 'success', 'data': {'success': true}}
            : _presensiPayload(
                asdoss: const [], kriterias: [_kriteria('9')]),
        captured: captured.add,
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: _Launcher(child: _page(pertemuan: _pertemuanB())),
      ));
      await _flush(tester);
      expect(find.text('FORM VALIDASI'), findsOneWidget,
          reason: 'form validasi belum termuat setelah detail presensi');

      await tester.ensureVisible(find.text('Validasi Presensi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validasi Presensi'));
      await _flush(tester);

      expect(captured, isNotEmpty);
      final body = captured.last;
      // Tanpa asdos: indeks 0 konsisten dengan key penilaian, tanpa npm.
      expect(body['asdos_npms'], <String>[]);
      expect(body['asdospenilaian'], {'0_9': '91'});
      // Biarkan SnackBar selesai agar tidak ada timer menggantung.
      await tester.pump(const Duration(seconds: 6));
    });
  });
}