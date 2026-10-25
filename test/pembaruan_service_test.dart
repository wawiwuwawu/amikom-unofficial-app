import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_amikom/models/app_failure.dart';
import 'package:app_amikom/services/pembaruan_service.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adapter Dio palsu: menyajikan satu respons tetap dan menghitung jumlah
/// request — dipakai untuk memastikan throttle tidak meng-hammer endpoint
/// dan unduhan tidak diulang saat APK versi sama masih valid.
class _AdapterTetap implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;
  int jumlahRequest = 0;

  _AdapterTetap(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    jumlahRequest++;
    return handler(options);
  }
}

class _AdapterGagal implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'koneksi palsu gagal',
    );
  }
}

ResponseBody _jsonOk(Map<String, dynamic> body) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
      Headers.contentLengthHeader: ['${bytes.length}'],
    },
  );
}

Map<String, dynamic> _releaseJson({
  String tag = 'v1.13.0',
  String? namaAsset = 'app-release.apk',
  String? digest = 'sha256:aaaa',
  List<String>? namaAssets,
}) {
  final assets = [
    for (final nama in namaAssets ?? [?namaAsset])
      {
        'name': nama,
        'browser_download_url': 'https://github.test/download/$nama',
        'digest': ?digest,
      },
  ];
  return {
    'tag_name': tag,
    'body': 'Catatan rilis v${tag.substring(1)}',
    'assets': assets,
  };
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PembaruanService.instance.resetUntukTest();
  });

  group('bandingkanVersi', () {
    test('numerik per segmen, bukan leksikografis', () {
      expect(PembaruanService.bandingkanVersi('1.2.10', '1.2.9'), 1);
      expect(PembaruanService.bandingkanVersi('1.2.9', '1.2.10'), -1);
      expect(PembaruanService.bandingkanVersi('1.13.0', '1.12.0'), 1);
      expect(PembaruanService.bandingkanVersi('1.12.0', '1.13.0'), -1);
    });

    test('sama & panjang beda dianggap setara', () {
      expect(PembaruanService.bandingkanVersi('1.12.0', '1.12.0'), 0);
      expect(PembaruanService.bandingkanVersi('1.12', '1.12.0'), 0);
    });
  });

  group('dariResponseJson', () {
    test('tag v dipangkas, digest sha256 diambil (lowercase)', () {
      final info = PembaruanService.dariResponseJson(
        _releaseJson(tag: 'v1.13.0', digest: 'sha256:ABCDEF'),
        '1.12.0',
      );
      expect(info, isNotNull);
      expect(info!.versi, '1.13.0');
      expect(info.urlApk, 'https://github.test/download/app-release.apk');
      expect(info.sha256, 'abcdef');
      expect(info.catatan, contains('Catatan rilis'));
    });

    test('versi sama / lebih lama / tanpa tag → null', () {
      expect(
        PembaruanService.dariResponseJson(_releaseJson(), '1.13.0'),
        isNull,
      );
      expect(
        PembaruanService.dariResponseJson(_releaseJson(), '2.0.0'),
        isNull,
      );
      expect(
        PembaruanService.dariResponseJson(
          _releaseJson()..remove('tag_name'),
          '1.12.0',
        ),
        isNull,
      );
    });

    test('tanpa asset APK → null', () {
      expect(
        PembaruanService.dariResponseJson(
          _releaseJson(namaAsset: 'checksums.txt'),
          '1.12.0',
        ),
        isNull,
      );
    });

    test('asset release dipilih di atas asset APK lain', () {
      final info = PembaruanService.dariResponseJson(
        _releaseJson(namaAssets: ['app-arm64-v8a.apk', 'app-release.apk']),
        '1.12.0',
      );
      expect(info!.namaApk, 'app-release.apk');
    });

    test(
      'digest non-sha256 / rusak → sha256 null (unduh tanpa verifikasi)',
      () {
        expect(
          PembaruanService.dariResponseJson(
            _releaseJson(digest: 'md5:xyz'),
            '1.12.0',
          )!.sha256,
          isNull,
        );
        expect(
          PembaruanService.dariResponseJson(
            _releaseJson(digest: null),
            '1.12.0',
          )!.sha256,
          isNull,
        );
      },
    );
  });

  group('cekPembaruan (adapter Dio palsu)', () {
    test('update lebih baru → info dikembalikan + cache terisi', () async {
      final dio = Dio();
      final adapter = _AdapterTetap((_) => _jsonOk(_releaseJson()));
      dio.httpClientAdapter = adapter;
      final service = PembaruanService.instance
        ..gantiDioUntukTest(dio)
        ..pakaiVersiUntukTest('1.12.0')
        ..pakaiUrlUntukTest('https://github.test/releases/latest');

      final info = await service.cekPembaruan();
      expect(info, isNotNull);
      expect(info!.versi, '1.13.0');
      expect(service.hasilTerakhir?.versi, '1.13.0');
      expect(adapter.jumlahRequest, 1);
    });

    test(
      'throttle 24 jam: pemanggilan kedua tanpa paksa tidak request ulang',
      () async {
        final dio = Dio();
        final adapter = _AdapterTetap((_) => _jsonOk(_releaseJson()));
        dio.httpClientAdapter = adapter;
        final service = PembaruanService.instance
          ..gantiDioUntukTest(dio)
          ..pakaiVersiUntukTest('1.12.0')
          ..pakaiUrlUntukTest('https://github.test/releases/latest');

        await service.cekPembaruan();
        final kedua = await service.cekPembaruan();
        expect(adapter.jumlahRequest, 1);
        expect(kedua!.versi, '1.13.0');
      },
    );

    test('cek paksa tetap request ulang meski throttle aktif', () async {
      final dio = Dio();
      final adapter = _AdapterTetap((_) => _jsonOk(_releaseJson()));
      dio.httpClientAdapter = adapter;
      final service = PembaruanService.instance
        ..gantiDioUntukTest(dio)
        ..pakaiVersiUntukTest('1.12.0')
        ..pakaiUrlUntukTest('https://github.test/releases/latest');

      await service.cekPembaruan();
      await service.cekPembaruan(paksa: true);
      expect(adapter.jumlahRequest, 2);
    });

    test(
      'gagal jaringan tanpa paksa → fail-open (cache, tanpa lempar)',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _AdapterGagal();
        final service = PembaruanService.instance
          ..gantiDioUntukTest(dio)
          ..pakaiVersiUntukTest('1.12.0')
          ..pakaiUrlUntukTest('https://github.test/releases/latest');

        final hasil = await service.cekPembaruan();
        expect(hasil, isNull);
      },
    );

    test('gagal jaringan dengan paksa → AppFailure ramah-pengguna', () async {
      final dio = Dio();
      dio.httpClientAdapter = _AdapterGagal();
      final service = PembaruanService.instance
        ..gantiDioUntukTest(dio)
        ..pakaiVersiUntukTest('1.12.0')
        ..pakaiUrlUntukTest('https://github.test/releases/latest');

      await expectLater(
        service.cekPembaruan(paksa: true),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.message,
            'pesan',
            'Gagal memeriksa pembaruan. Coba lagi nanti.',
          ),
        ),
      );
    });

    test('URL env kosong → fitur mati tanpa request', () async {
      final dio = Dio();
      final adapter = _AdapterTetap((_) => _jsonOk(_releaseJson()));
      dio.httpClientAdapter = adapter;
      final service = PembaruanService.instance
        ..gantiDioUntukTest(dio)
        ..pakaiVersiUntukTest('1.12.0')
        ..pakaiUrlUntukTest('');

      final info = await service.cekPembaruan();
      expect(info, isNull);
      expect(adapter.jumlahRequest, 0);
    });
  });

  group('lewati versi', () {
    test('dilewati true setelah lewati; versi baru kembali false', () async {
      final dio = Dio();
      dio.httpClientAdapter = _AdapterTetap((_) => _jsonOk(_releaseJson()));
      final service = PembaruanService.instance
        ..gantiDioUntukTest(dio)
        ..pakaiVersiUntukTest('1.12.0')
        ..pakaiUrlUntukTest('https://github.test/releases/latest');

      final info = (await service.cekPembaruan())!;
      expect(await service.dilewati(info), isFalse);

      await service.lewatiVersi('1.13.0');
      expect(await service.dilewati(info), isTrue);
      // Cache ikut dikosongkan supaya banner hilang tanpa cek ulang.
      expect(service.hasilTerakhir, isNull);

      final infoBaru = InfoPembaruan(
        versi: '1.14.0',
        catatan: '',
        urlApk: 'https://github.test/x.apk',
        namaApk: 'app-release.apk',
        sha256: null,
      );
      expect(await service.dilewati(infoBaru), isFalse);
    });
  });

  group('unduhApk (berkas sungguhan di direktori test)', () {
    late Directory dir;
    const isiApk = [1, 2, 3, 4, 5, 6, 7, 8];
    final shaIsi = sha256.convert(isiApk).toString();

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('pembaruan_test');
      PembaruanService.instance.gantiDirektoriUnduhUntukTest(dir);
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    InfoPembaruan info({String? sha, String nama = 'app-release.apk'}) =>
        InfoPembaruan(
          versi: '1.13.0',
          catatan: '',
          urlApk: 'https://github.test/download/$nama',
          namaApk: nama,
          sha256: sha,
        );

    test(
      'unduh sukses + sha cocok → berkas ada, progress terpanggil',
      () async {
        final dio = Dio();
        final adapter = _AdapterTetap(
          (_) => ResponseBody.fromBytes(
            isiApk,
            200,
            headers: {
              Headers.contentLengthHeader: ['${isiApk.length}'],
            },
          ),
        );
        dio.httpClientAdapter = adapter;
        final service = PembaruanService.instance..gantiDioUntukTest(dio);

        var panggilanProgress = 0;
        final path = await service.unduhApk(
          info(sha: shaIsi),
          onProgress: (_, _) => panggilanProgress++,
        );

        expect(panggilanProgress, greaterThan(0));
        expect(await File(path).exists(), isTrue);
        expect(File(path).readAsBytesSync(), isiApk);
      },
    );

    test('sha tidak cocok → AppFailure "rusak" dan berkas dihapus', () async {
      final dio = Dio();
      dio.httpClientAdapter = _AdapterTetap(
        (_) => ResponseBody.fromBytes(isiApk, 200),
      );
      final service = PembaruanService.instance..gantiDioUntukTest(dio);

      await expectLater(
        service.unduhApk(info(sha: '0' * 64)),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.message,
            'pesan',
            'Berkas pembaruan rusak saat diunduh. Coba lagi.',
          ),
        ),
      );
      // Tidak ada berkas sisa di folder unduhan.
      final folder = Directory('${dir.path}/pembaruan');
      if (await folder.exists()) {
        expect(await folder.list().isEmpty, isTrue);
      }
    });

    test(
      'unduhan valid untuk versi sama dipakai ulang (tanpa request baru)',
      () async {
        final dio = Dio();
        final adapter = _AdapterTetap(
          (_) => ResponseBody.fromBytes(
            isiApk,
            200,
            headers: {
              Headers.contentLengthHeader: ['${isiApk.length}'],
            },
          ),
        );
        dio.httpClientAdapter = adapter;
        final service = PembaruanService.instance..gantiDioUntukTest(dio);

        final pertama = await service.unduhApk(info(sha: shaIsi));
        final kedua = await service.unduhApk(info(sha: shaIsi));
        expect(pertama, kedua);
        expect(adapter.jumlahRequest, 1);
      },
    );

    test(
      'unduh gagal jaringan → berkas parsial dihapus + AppFailure',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _AdapterGagal();
        final service = PembaruanService.instance..gantiDioUntukTest(dio);

        await expectLater(
          service.unduhApk(info(sha: null)),
          throwsA(
            isA<AppFailure>().having(
              (e) => e.message,
              'pesan',
              'Gagal mengunduh pembaruan. Coba lagi nanti.',
            ),
          ),
        );
        final folder = Directory('${dir.path}/pembaruan');
        if (await folder.exists()) {
          expect(await folder.list().isEmpty, isTrue);
        }
      },
    );
  });

  group('pasang (pembuka palsu)', () {
    test('pembuka sukses → tidak lempar', () async {
      PembaruanService.instance.gantiPembukaUntukTest((_) async => true);
      await PembaruanService.instance.pasang('/x/y.apk');
    });

    test('pembuka gagal → AppFailure dengan panduan izin', () async {
      PembaruanService.instance.gantiPembukaUntukTest((_) async => false);
      await expectLater(
        PembaruanService.instance.pasang('/x/y.apk'),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.message,
            'pesan',
            contains('Install unknown apps'),
          ),
        ),
      );
    });
  });
}
