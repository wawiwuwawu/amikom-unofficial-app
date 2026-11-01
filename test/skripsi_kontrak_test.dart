// Regresi kontrak BE Nov 2026 untuk Skripsi & Pusat Studi: field baru
// GET /skripsi (pembimbing[], status_proposal, peringatan ACC), field baru
// baris bimbingan (pembimbing/urutan/status/komentar), endpoint baru
// DELETE /skripsi/bimbingan/:id, PUT /judul tanpa npm (diisi BE dari
// token), dan field baru joined-page pusat studi. Bentuk halaman lama
// harus tetap ter-parse (field baru null/[]).

import 'dart:convert';
import 'dart:typed_data';

import 'package:app_amikom/models/pusat_studi.dart';
import 'package:app_amikom/models/sp.dart';
import 'package:app_amikom/models/skripsi.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/skripsi_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _SkripsiAdapter implements HttpClientAdapter {
  Map<String, dynamic>? putJudulBody;
  String? deletedBimbinganId;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Future<ResponseBody> json(Object? data, [int code = 200]) async =>
        ResponseBody.fromString(
          jsonEncode({'status': 'success', 'data': data}),
          code,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );

    final path = options.path;
    if (path == '/api/v1/skripsi/judul' && options.method == 'PUT') {
      // Body PUT bertipe Map langsung (bukan form-data).
      putJudulBody = Map<String, dynamic>.from(options.data as Map);
      return json(null);
    }
    if (path.startsWith('/api/v1/skripsi/bimbingan/') &&
        options.method == 'DELETE') {
      deletedBimbinganId = path.split('/').last;
      return json(null);
    }
    if (path == '/api/v1/skripsi/bimbingan/opsi' && options.method == 'GET') {
      return json({
        'opsi_progres': ['Judul/Tema', 'BAB 1', 'BAB 2', 'BAB 3'],
      });
    }
    return json(null);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  group('SkripsiMainData — kontrak BE Nov 2026 §1', () {
    test('membaca pembimbing[], status_proposal, dan peringatan ACC', () {
      final data = SkripsiMainData.fromJson({
        'informasi': <String>[],
        'dospem_assigned': true,
        'idauto': '1122',
        'nidn': '0503118701',
        'pembimbing': [
          {
            'urutan': 1,
            'label': 'Pembimbing I',
            'nama': 'Rahman Rosyidi',
            'idauto': '1122',
            'nidn': '0503118701',
            'pesan_bimbingan': null,
          },
          {
            'urutan': 2,
            'label': 'Pembimbing II',
            'nama': 'Dosen Kedua',
            'idauto': '1133',
            'nidn': '0503118702',
            'pesan_bimbingan': 'Belum pernah bimbingan',
          },
        ],
        'status_proposal': {
          'layak': true,
          'pesan': 'Ajuan proposal Anda dinyatakan layak',
          'komentar_pusat_studi': 'Perbaiki BAB 2',
          'reviewer': 'Dosen Reviewer',
        },
        'peringatan_acc_ujian': [
          'Dosen pembimbing Rahman Rosyidi belum melakukan proses ACC Ujian',
        ],
        'peringatan_acc_plagiarisme': <String>[],
      });

      expect(data.pembimbing.length, 2);
      final dosbim2 = data.pembimbing[1];
      expect(dosbim2.urutan, 2);
      expect(dosbim2.label, 'Pembimbing II');
      expect(dosbim2.idauto, '1133');
      expect(dosbim2.nidn, '0503118702');
      expect(dosbim2.pesanBimbingan, 'Belum pernah bimbingan');

      expect(data.statusProposal?.layak, isTrue);
      expect(data.statusProposal?.pesan, 'Ajuan proposal Anda dinyatakan layak');
      expect(data.statusProposal?.komentarPusatStudi, 'Perbaiki BAB 2');
      expect(data.statusProposal?.reviewer, 'Dosen Reviewer');

      expect(data.peringatanAccUjian.single,
          contains('belum melakukan proses ACC Ujian'));
      expect(data.peringatanAccPlagiarisme, isEmpty);
    });

    test('bentuk halaman lama: field baru null/[] tanpa error', () {
      final data = SkripsiMainData.fromJson({
        'informasi': <String>[],
        'dospem_assigned': false,
      });

      expect(data.pembimbing, isEmpty);
      expect(data.statusProposal, isNull);
      expect(data.peringatanAccUjian, isEmpty);
      expect(data.peringatanAccPlagiarisme, isEmpty);
    });
  });

  group('SkripsiBimbinganItem — kontrak BE Nov 2026 §2', () {
    test('baris baru membawa pembimbing, urutan, status, komentar', () {
      final item = SkripsiBimbinganItem.fromJson({
        'id': '4567',
        'tanggal': '2026-10-30',
        'progres': 'BAB 1',
        'keterangan': 'Draft Bab 1',
        'pembimbing': 'Dosen Kedua',
        'urutan_pembimbing': 2,
        'status': 'Di Terima',
        'komentar': 'Lanjutkan ke metodologi',
        'idauto': '1133',
        'nidn': '0503118702',
      });

      expect(item.id, '4567');
      expect(item.pembimbing, 'Dosen Kedua');
      expect(item.urutanPembimbing, 2);
      expect(item.status, 'Di Terima');
      expect(item.komentar, 'Lanjutkan ke metodologi');
    });

    test('baris lama tanpa field dosbim tetap ter-parse', () {
      final item = SkripsiBimbinganItem.fromJson({
        'id': '12',
        'tanggal': '2026-10-01',
        'progres': 'BAB 2',
        'keterangan': 'Revisi',
      });

      expect(item.pembimbing, isNull);
      expect(item.urutanPembimbing, isNull);
      expect(item.status, isNull);
      expect(item.komentar, isNull);
    });
  });

  group('SkripsiService — endpoint BE Nov 2026', () {
    late _SkripsiAdapter adapter;

    setUp(() {
      adapter = _SkripsiAdapter();
      ApiClient.instance.dio.httpClientAdapter = adapter;
    });

    test('hapusBimbingan memanggil DELETE /skripsi/bimbingan/:id', () async {
      final res = await SkripsiService().hapusBimbingan('4567');

      expect(adapter.deletedBimbinganId, '4567');
      expect(res['message'] ?? res['status'], isNotNull);
    });

    test('updateJudulSkripsi tidak lagi mengirim npm (diisi BE dari token)',
        () async {
      await SkripsiService().updateJudulSkripsi(
        judulId: 'Sistem Informasi',
        judulEn: 'Information System',
      );

      expect(adapter.putJudulBody?['judul_skripsi_id'], 'Sistem Informasi');
      expect(adapter.putJudulBody?['judul_skripsi_en'], 'Information System');
      expect(adapter.putJudulBody?.containsKey('npm'), isFalse,
          reason: 'kontrak BE §4: npm diisi BE dari token login');
    });

    test('getOpsiBimbingan membaca opsi_progres dari <select> portal (BE 2026-11-02)',
        () async {
      final opsi = await SkripsiService().getOpsiBimbingan();

      expect(opsi, ['Judul/Tema', 'BAB 1', 'BAB 2', 'BAB 3']);
    });
  });

  group('SpRekomendasiData — kontrak BE 2026-11-02 (breaking)', () {
    test('kategori_wajib (C- ke bawah) + kategori_info (hanya C)', () {
      final data = SpRekomendasiData.fromJson({
        'has_rekomendasi': true,
        'warning_message': 'Anda memiliki 1 matakuliah wajib SP.',
        'total_rekomendasi': 2,
        'total_sks': 6,
        'kategori_wajib': [
          {
            'kode': 'PSSIW004',
            'mkl': 'Manajemen Bisnis',
            'sks': 3,
            'nilai_sebelumnya': 'D',
            'bobot': 1,
            'kategori': 'wajib',
            'alasan': 'Nilai D (Wajib diperbaiki melalui SP)',
          },
        ],
        'kategori_info': [
          {
            'kode': 'PSSIW010',
            'mkl': 'Sistem Digital',
            'sks': 3,
            'nilai_sebelumnya': 'C',
            'bobot': 2,
            'kategori': 'info',
            'alasan': 'Nilai C (Dapat dipertimbangkan untuk SP)',
          },
        ],
      });

      expect(data.kategoriWajib.single.kode, 'PSSIW004');
      expect(data.kategoriWajib.single.kategori, 'wajib');
      expect(data.kategoriWajib.single.bobot, 1);
      expect(data.kategoriInfo.single.nilaiSebelumnya, 'C');
      expect(data.kategoriInfo.single.kategori, 'info');
    });

    test('tanpa field kategori per item → default wajib (toleran)', () {
      final data = SpRekomendasiData.fromJson({
        'has_rekomendasi': true,
        'total_rekomendasi': 1,
        'total_sks': 3,
        'kategori_wajib': [
          {'kode': 'X', 'mkl': 'Y', 'sks': 3},
        ],
      });

      expect(data.kategoriWajib.single.kategori, 'wajib');
      expect(data.kategoriWajib.single.bobot, isNull);
    });
  });

  group('PusatStudiJoinedPageData — kontrak BE Nov 2026 §5', () {    test('membaca id, pesan_status, saran, dan link pengisian proposal', () {
      final data = PusatStudiJoinedPageData.fromJson({
        'status_code': 'diterima',
        'status_text': 'Diterima',
        'can_submit_proposal': true,
        'id': '28',
        'pesan_status': 'Pengajuan anda dengan Tema Sistem Pakar Diterima',
        'saran_pusat_studi': 'Perdalam bab analisis',
        'link_pengisian_proposal': 'https://portal/skripsi',
      });

      expect(data.id, '28');
      expect(data.pesanStatus, contains('Diterima'));
      expect(data.saranPusatStudi, 'Perdalam bab analisis');
      expect(data.linkPengisianProposal, 'https://portal/skripsi');
    });

    test('kondisi tanpa banner: field baru null tanpa error', () {
      final data = PusatStudiJoinedPageData.fromJson({
        'status_code': '',
        'can_submit_proposal': false,
      });

      expect(data.id, isNull);
      expect(data.pesanStatus, isNull);
      expect(data.saranPusatStudi, isNull);
      expect(data.linkPengisianProposal, isNull);
    });
  });
}
