import 'package:app_amikom/services/deep_link_service.dart';
import 'package:app_amikom/services/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushService.tujuanDariData', () {
    test('url amikomstudent → detail notifikasi', () {
      expect(
        PushService.tujuanDariData({'url': 'amikomstudent://notifikasi/123'}),
        TujuanKetukan.notifikasi('123'),
      );
    });

    test('url amikomstudent menang atas notif_id', () {
      expect(
        PushService.tujuanDariData({
          'url': 'amikomstudent://notifikasi/11',
          'notif_id': '22',
        }),
        TujuanKetukan.notifikasi('11'),
      );
    });

    test('url http/https → siaran yang dibuka di browser', () {
      expect(
        PushService.tujuanDariData({'url': 'https://contoh/9'}),
        TujuanKetukan.siaranWeb(Uri.parse('https://contoh/9')),
      );
      expect(
        PushService.tujuanDariData({'url': 'http://contoh/9'}),
        TujuanKetukan.siaranWeb(Uri.parse('http://contoh/9')),
      );
    });

    test('kontrak BE baru: siaran https tidak jatuh ke notif_id', () {
      expect(
        PushService.tujuanDariData({'url': 'https://x/9', 'notif_id': '77'}),
        TujuanKetukan.siaranWeb(Uri.parse('https://x/9')),
      );
    });

    test('tanpa url: fallback notif_id — string maupun angka', () {
      expect(
        PushService.tujuanDariData({'notif_id': '456'}),
        TujuanKetukan.notifikasi('456'),
      );
      expect(
        PushService.tujuanDariData({'notif_id': 456}),
        TujuanKetukan.notifikasi('456'),
      );
    });

    test('bukan ketukan yang dikenal → null', () {
      expect(
        PushService.tujuanDariData({'url': 'mailto://notifikasi/9'}),
        isNull,
      );
      expect(
        PushService.tujuanDariData({'url': 'amikomstudent://pengumuman/9'}),
        isNull,
      );
      expect(PushService.tujuanDariData({}), isNull);
      expect(PushService.tujuanDariData({'notif_id': '   '}), isNull);
    });
  });

  group('PushService.displayIdDari (id notifikasi tray)', () {
    test('siaran dengan notif_id TIDAK memakai id mentah (hindari tabrakan tray)', () {
      final siaran = PushService.displayIdDari({
        'notif_id': '77',
        'url': 'https://siaran-contoh.test/pengumuman-77',
      });
      final privat = PushService.displayIdDari({
        'notif_id': '77',
        'url': 'amikomstudent://notifikasi/77',
      });

      expect(privat, 77);
      expect(siaran, isNot(77), reason: 'siaran dipatok ke hash url, bukan notif_id');
      expect(
        siaran,
        'https://siaran-contoh.test/pengumuman-77'.hashCode & 0x7fffffff,
      );
    });

    test('siaran tanpa notif_id memakai hash url yang stabil', () {
      const data = {'url': 'https://siaran-contoh.test/stabil'};
      expect(
        PushService.displayIdDari(data),
        PushService.displayIdDari(data),
        reason: 'siaran berulang harus memakai id yang sama agar tidak menumpuk',
      );
    });
  });

  group('PushService dedupe tujuan ketukan', () {
    // Id/url unik per tes: PushService serta DeepLinkService bersifat singleton
    // dan jendela dedupe 2 detik tidak boleh tertabru antar-tes. Antrean
    // pending dibersihkan di tearDown seperti pola
    // test/deep_link_service_test.dart.
    tearDown(() {
      DeepLinkService.instance.consumePendingId();
    });

    test('privat: id sama dalam 2 detik hanya diproses sekali', () {
      const data = {'url': 'amikomstudent://notifikasi/9301'};

      expect(
        PushService.instance.resolveTujuan(data),
        TujuanKetukan.notifikasi('9301'),
      );
      expect(
        PushService.instance.resolveTujuan(data),
        isNull,
        reason: 'duplikat dalam 2 detik harus diabaikan',
      );
    });

    test('siaran: url sama dalam 2 detik hanya dibuka sekali', () {
      const data = {'url': 'https://siaran-contoh.test/9302'};

      expect(
        PushService.instance.resolveTujuan(data),
        TujuanKetukan.siaranWeb(Uri.parse('https://siaran-contoh.test/9302')),
      );
      expect(
        PushService.instance.resolveTujuan(data),
        isNull,
        reason: 'ketukan siaran ganda dalam 2 detik harus diabaikan',
      );
    });

    test('dua siaran berbeda beruntun tetap diproses', () {
      expect(
        PushService.instance.resolveTujuan({'url': 'https://siaran-contoh.test/a'}),
        TujuanKetukan.siaranWeb(Uri.parse('https://siaran-contoh.test/a')),
      );
      expect(
        PushService.instance.resolveTujuan({'url': 'https://siaran-contoh.test/b'}),
        TujuanKetukan.siaranWeb(Uri.parse('https://siaran-contoh.test/b')),
        reason: 'dedupe siaran tidak boleh menelan url yang berbeda',
      );
    });

    test('siaran tidak mengganggu dedupe privat', () {
      expect(
        PushService.instance.resolveTujuan({'url': 'https://siaran-contoh.test/c'}),
        TujuanKetukan.siaranWeb(Uri.parse('https://siaran-contoh.test/c')),
      );
      expect(
        PushService.instance.resolveTujuan({'notif_id': '9303'}),
        TujuanKetukan.notifikasi('9303'),
        reason: 'ketukan privat setelah siaran tetap diproses',
      );
      expect(
        PushService.instance.resolveTujuan({'notif_id': '9303'}),
        isNull,
        reason: 'dedupe privat tetap aktif',
      );
    });
  });
}
