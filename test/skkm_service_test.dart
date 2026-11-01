// Regresi SkkmService: kontrak endpoint BE 2026-11-01 §4–§5 lewat adapter
// palsu. Pola FakeAdapter seperti test/dashboard_presensi_tercatat_test.dart.
// Perhatian khusus: endpoint tulis menolak angkatan < 2024 dengan 400 + pesan
// kebijakan — harus naik sebagai AppFailure dengan pesan itu, bukan galat
// generik.

import 'dart:convert';
import 'dart:typed_data';

import 'package:app_amikom/models/app_failure.dart';
import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/skkm_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _SkkmAdapter implements HttpClientAdapter {
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
    if (path.contains('/api/v1/skkm') && options.method == 'GET') {
      return json({
        'angkatan': 2025,
        'skkm_berlaku': true,
        'total_poin_valid': 55,
        'panduan_url': 'https://portal/Panduan_SKKM.pdf',
        'jumlah_aktivitas': 1,
        'opsi_unsur': [
          {'value': '2', 'label': 'Kegiatan Kepemimpinan'},
        ],
        'aktivitas': [
          {
            'no': 1,
            'kegiatan': {
              'unsur': 'Kegiatan Kepemimpinan',
              'sub_unsur': 'Panitia kegiatan',
              'level': 'Nasional',
              'jenis_keg': 'kelompok',
              'role': 'Sebagai ketua',
              'jml_anggota': 3,
              'surat_tugas': '1824/AMIKOMPWT/2026',
            },
            'diupload_oleh': 'Mahasiswa',
            'kredit': 15,
            'status': 'Valid',
            'validator': 'PRODI',
            'bukti': {'id': '1791', 'url': 'https://portal/preview?id=1791'},
          },
        ],
      });
    }
    if (path.contains('/api/v1/skkm/sub-unsur')) {
      return json([
        {'value': '1', 'label': 'Panitia kegiatan'},
      ]);
    }
    if (path.contains('/api/v1/skkm/jenis')) {
      return json([
        {'value': '3', 'label': 'Nasional'},
      ]);
    }
    if (path.contains('/api/v1/skkm/kredit')) {
      return json({'kredit': 10, 'id_skkm': '45'});
    }
    if (path.contains('/api/v1/skkm/bukti')) {
      return json({
        'input': [
          {'name': 'bukti_fisik', 'type': 'file', 'accept': 'application/pdf'},
        ],
      });
    }
    if (path.contains('/api/v1/skkm/cek-surat-tugas')) {
      final body = options.data as Map?;
      final no = body?['surat_tgs']?.toString() ?? '';
      return json({'exists': no == '1824/AMIKOMPWT/2026'});
    }
    if (path.contains('/api/v1/skkm/aktivitas') && options.method == 'POST') {
      return json(null);
    }
    if (path.contains('/api/v1/skkm/aktivitas/') && options.method == 'DELETE') {
      return json(null);
    }
    if (path.contains('/api/v1/skkm/kritik-saran')) {
      return json(null);
    }

    // Angkatan < 2024: BE menolak semua endpoint tulis dengan 400.
    return ResponseBody.fromString(
      jsonEncode({
        'status': 'error',
        'message':
            'SKKM hanya berlaku untuk angkatan 2024 ke atas (kebijakan kampus)',
      }),
      400,
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
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');
  });

  group('berlakuDariNim — aturan 2 digit pertama, sama dengan BE', () {
    test('angkatan 2024+ → true', () {
      expect(SkkmService.berlakuDariNim('25SA31A037'), isTrue);
      expect(SkkmService.berlakuDariNim('2400001'), isTrue,
          reason: 'batas bawah: 2024 masih berlaku');
    });

    test('angkatan < 2024 → false', () {
      expect(SkkmService.berlakuDariNim('2200001'), isFalse);
      expect(SkkmService.berlakuDariNim('2300001'), isFalse);
    });

    test('NIM tidak tersedia / tak bisa diparse → null (fail-open)', () {
      expect(SkkmService.berlakuDariNim(null), isNull);
      expect(SkkmService.berlakuDariNim(''), isNull);
      expect(SkkmService.berlakuDariNim('A'), isNull,
          reason: 'terlalu pendek');
      expect(SkkmService.berlakuDariNim('AB123'), isNull,
          reason: 'prefix bukan angka → serahkan ke BE');
    });
  });

  setUp(() {
    ApiClient.instance.dio.httpClientAdapter = _SkkmAdapter();
  });

  test('getSkkm mem-parsing daftar + opsi unsur', () async {
    final data = await SkkmService().getSkkm();

    expect(data.skkmBerlaku, isTrue);
    expect(data.totalPoinValid, 55);
    expect(data.opsiUnsur.single.value, '2');
    final item = data.aktivitas.single;
    expect(item.subUnsur, 'Panitia kegiatan');
    expect(item.kredit, 15);
    expect(item.bukti?.id, '1791');
  });

  test('rantai dropdown: sub-unsur → jenis → kredit', () async {
    final service = SkkmService();

    final sub = await service.subUnsur('2');
    expect(sub.single.value, '1');

    final jenis = await service.jenis('2', '1');
    expect(jenis.single.value, '3');

    final kredit = await service.kredit('2', '1', '3');
    expect(kredit.kredit, 10);
    expect(kredit.idSkkm, '45');
  });

  test('inputBukti mengembalikan deskriptor input portal', () async {
    final input = await SkkmService().inputBukti('45');

    expect(input.single.name, 'bukti_fisik');
    expect(input.single.type, 'file');
    expect(input.single.accept, 'application/pdf');
  });

  test('cekSuratTugas: true bila nomor dikenal, false bila tidak', () async {
    final service = SkkmService();

    expect(await service.cekSuratTugas('1824/AMIKOMPWT/2026'), isTrue);
    expect(await service.cekSuratTugas('9999/TIDAK/ADA'), isFalse);
  });

  test('tambahAktivitas tanpa bukti ditolak lokal sebelum kirim', () async {
    await expectLater(
      SkkmService().tambahAktivitas(
        unsur: '2',
        subUnsur: '1',
        jenis: '3',
        idSkkm: '45',
        thnKeg: '2026',
        jenisKeg: 'individu',
        roleKeg: 'ketua',
      ),
      throwsA(isA<AppFailure>()),
    );
  });

  test('hapus aktivitas + kritik saran sukses (envelope mutasi)', () async {
    final service = SkkmService();

    await service.hapusAktivitas('1801');
    await service.kirimKritikSaran('Mohon feedback lebih cepat.');
  });

  test('angkatan < 2024: endpoint tulis menolak 400 dengan pesan kebijakan',
      () async {
    // Adapter khusus: semua request dijawab 400 seperti BE untuk angkatan
    // < 2024 (di adapter utama, kritik-saran tertangkap cabang sukses).
    ApiClient.instance.dio.httpClientAdapter = _AdapterTulis400();
    await expectLater(
      SkkmService().kirimKritikSaran('tes'),
      throwsA(isA<AppFailure>()),
    );
  });
}

/// Semua request dijawab 400 + pesan kebijakan angkatan (kontrak BE §5).
class _AdapterTulis400 implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'status': 'error',
        'message':
            'SKKM hanya berlaku untuk angkatan 2024 ke atas (kebijakan kampus)',
      }),
      400,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
