import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/services/api_client.dart';
import 'package:app_amikom/services/push_service.dart';
import 'package:app_amikom/services/push_token_provider.dart';

class _MockReply {
  final int statusCode;
  final Map<String, dynamic> body;

  const _MockReply({this.statusCode = 200, required this.body});
}

/// Adapter palsu yang merekam setiap request: method + path + body.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final _MockReply Function(RequestOptions options) _handler;
  final List<RequestOptions> tercatat = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    tercatat.add(options);
    final reply = _handler(options);
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Gateway FCM palsu: izin bisa diatur, token tetap, stream kosong.
class _FakeGateway implements MessagingGateway {
  _FakeGateway(this.izin, {this.izinSistem = false});

  final bool izin;

  /// Hasil probe izin TANPA dialog (mis. sudah diizinkan di Pengaturan).
  final bool izinSistem;
  int panggilanToken = 0;
  int panggilanIzin = 0;
  int panggilanProbe = 0;

  static const _token = 'fcm-token-palsu';

  @override
  Future<String?> getToken() async {
    panggilanToken += 1;
    return _token;
  }

  @override
  Future<bool> mintaIzin() async {
    panggilanIzin += 1;
    return izin;
  }

  @override
  Future<bool> izinSudahDiberikan() async {
    panggilanProbe += 1;
    return izinSistem;
  }

  @override
  Stream<Map<String, dynamic>> get tokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessage => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessageOpened => const Stream.empty();

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => null;
}

/// Membaca body request terakhir yang tercatat pada [adapter].
String _bodyTerakhir(_FakeAdapter adapter) {
  final options = adapter.tercatat.last;
  return options.data is String ? options.data as String : '${options.data}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000\n');
  });

  group('PushService aktivasi default-on', () {
    late _FakeAdapter adapter;
    late _FakeGateway gateway;

    setUp(() {
      // Guard sesi statis: setiap test butuh percobaan aktivasi baru.
      PushService.resetAktivasiUntukTest();
      adapter = _FakeAdapter((options) {
        if (options.path.contains('/optin')) {
          return const _MockReply(
            body: {'status': 'success', 'data': {'enabled': false, 'token_count': 0}},
          );
        }
        return const _MockReply(
          body: {
            'status': 'success',
            'data': {'enabled': true, 'token_count': 1},
            'success': true,
            'message': 'Token notifikasi didaftarkan untuk perangkat ini',
          },
        );
      });
      gateway = _FakeGateway(true);
      ApiClient.instance.dio.httpClientAdapter = adapter;
      SharedPreferences.setMockInitialValues({});
    });

    test('(a) sudah aktif: izin dicek lalu token disegarkan & didaftarkan', () async {
      adapter = _FakeAdapter((options) {
        return const _MockReply(
          body: {'status': 'success', 'data': {'enabled': true, 'token_count': 2}},
        );
      });
      ApiClient.instance.dio.httpClientAdapter = adapter;

      await PushService.instance.aktifkanJikaBelumPernah(gateway: gateway);

      final metode = adapter.tercatat.map((o) => '${o.method} ${o.path}').toList();
      expect(metode, contains('GET /api/v1/notifikasi/optin'));
      expect(metode, contains('POST /api/v1/notifikasi/device-token'));
      expect(_bodyTerakhir(adapter), contains('fcm-token-palsu'));
      // Hanya SATU getToken meski izin + daftar ulang dijalankan.
      expect(gateway.panggilanToken, 1);
    });

    test('(b) user belum punya token: izin diminta lalu token langsung terdaftar', () async {
      await PushService.instance.aktifkanJikaBelumPernah(gateway: gateway);

      final metode = adapter.tercatat.map((o) => '${o.method} ${o.path}').toList();
      expect(metode, contains('GET /api/v1/notifikasi/optin'));
      expect(metode, contains('POST /api/v1/notifikasi/device-token'));
      expect(_bodyTerakhir(adapter), contains('fcm-token-palsu'));
      // Default-on: tanpa tombol, izin diminta app sendiri.
      expect(gateway.panggilanIzin, 1);
    });

    test('(c) guard sesi: kedua method berurutan -> gateway hanya dipakai SEKALI', () async {
      await PushService.instance.aktifkanJikaBelumPernah(gateway: gateway);
      await PushService.instance.aktifkanSetelahLogin(gateway: gateway);

      expect(gateway.panggilanToken, 1);
      expect(gateway.panggilanIzin, 1);
      final posting = adapter.tercatat
          .where((o) => '${o.method} ${o.path}' == 'POST /api/v1/notifikasi/device-token')
          .length;
      expect(posting, 1, reason: 'tak boleh dobel POST di launch yang sama');
    });

    test('(d) izin ditolak: tidak ada POST, penolakan dicatat, panggilan kedua tak bertanya lagi', () async {
      final menolak = _FakeGateway(false);

      await PushService.instance.aktifkanJikaBelumPernah(gateway: menolak);

      final metode = adapter.tercatat.map((o) => '${o.method} ${o.path}').toList();
      expect(metode, contains('GET /api/v1/notifikasi/optin'));
      expect(metode, isNot(contains('POST /api/v1/notifikasi/device-token')));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('push_izin_pernah_ditolak'), isTrue);

      // Percobaan kedua di launch yang sama: guard sesi menahannya.
      await PushService.instance.aktifkanSetelahLogin(gateway: menolak);
      expect(menolak.panggilanIzin, 1);
      expect(menolak.panggilanToken, 0);
    });

    test('izin sudah pernah ditolak: tidak menyentuh server sama sekali', () async {
      SharedPreferences.setMockInitialValues({'push_izin_pernah_ditolak': true});

      await PushService.instance.aktifkanJikaBelumPernah(gateway: gateway);

      expect(adapter.tercatat, isEmpty);
      expect(gateway.panggilanToken, 0);
    });

    test(
      'flag penolakan basi + izin SUDAH diberikan lewat Pengaturan sistem: '
      'push pulih sendiri tanpa dialog (regresi jalan-buntu M1)',
      () async {
        SharedPreferences.setMockInitialValues({'push_izin_pernah_ditolak': true});
        final sistemSudahIzinkan = _FakeGateway(
          false,
          izinSistem: true,
        ); // dialog ditolak, sistem mengizinkan

        await PushService.instance.aktifkanJikaBelumPernah(
          gateway: sistemSudahIzinkan,
        );

        final metode = adapter.tercatat.map((o) => '${o.method} ${o.path}').toList();
        expect(metode, contains('POST /api/v1/notifikasi/device-token'));
        expect(
          sistemSudahIzinkan.panggilanIzin,
          0,
          reason: 'izin sudah ada: tak boleh muncul dialog',
        );
        expect(sistemSudahIzinkan.panggilanProbe, greaterThan(0));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('push_izin_pernah_ditolak'), isFalse);
      },
    );

    test(
      'mulaiSesiBaru: logout lalu login di proses yang sama tetap mendaftarkan token',
      () async {
        await PushService.instance.aktifkanSetelahLogin(gateway: gateway);
        PushService.instance.mulaiSesiBaru();

        await PushService.instance.aktifkanSetelahLogin(gateway: gateway);

        final posting = adapter.tercatat
            .where(
              (o) =>
                  '${o.method} ${o.path}' ==
                  'POST /api/v1/notifikasi/device-token',
            )
            .length;
        expect(posting, 2, reason: 'sesi login baru -> registrasi diizinkan lagi');
      },
    );

    test(
      'sheet panduan tercatat sekali-tampil di SharedPreferences',
      () async {
        expect(await PushService.sheetSudahDitampilkan(), isFalse);
        await PushService.tandaiSheetDitampilkan();
        expect(await PushService.sheetSudahDitampilkan(), isTrue);
      },
    );

    test('gagal server (503 FCM mati): tidak melempar, tidak menandai izin ditolak', () async {
      adapter = _FakeAdapter((_) => const _MockReply(
            statusCode: 503,
            body: {'status': 'error', 'message': 'belum dikonfigurasi'},
          ));
      ApiClient.instance.dio.httpClientAdapter = adapter;

      await PushService.instance.aktifkanJikaBelumPernah(gateway: gateway);
      await PushService.instance.aktifkanJikaBelumPernah(gateway: gateway);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('push_izin_pernah_ditolak'), isNull);
      // Tidak ada penolakan tercatat: aplikasi akan mencoba lagi di launch
      // berikutnya, sehingga push otomatis nyala begitu FCM dikonfigurasi.
      // Kegagalan terjadi sebelum izin diminta; percobaan kedua di launch yang
      // sama sudah dilewati guard sesi.
      expect(gateway.panggilanIzin, 0);
    });

    test('setelah login: izin diberikan -> token terdaftar', () async {
      await PushService.instance.aktifkanSetelahLogin(gateway: gateway);

      final metode = adapter.tercatat.map((o) => '${o.method} ${o.path}').toList();
      expect(metode, contains('POST /api/v1/notifikasi/device-token'));
      expect(_bodyTerakhir(adapter), contains('fcm-token-palsu'));
    });

    test('setelah login tapi FCM mati (503): login tidak boleh terganggu', () async {
      adapter = _FakeAdapter((_) => const _MockReply(
            statusCode: 503,
            body: {'status': 'error', 'message': 'belum dikonfigurasi'},
          ));
      ApiClient.instance.dio.httpClientAdapter = adapter;

      await PushService.instance.aktifkanSetelahLogin(gateway: gateway);
      // Sampai di sini tanpa melempar = alur login aman.
    });
  });
}
