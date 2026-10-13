import 'package:app_amikom/services/deep_link_service.dart';
import 'package:app_amikom/services/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushService.idDariData', () {
    test('mengambil id dari url amikomstudent', () {
      expect(
        PushService.idDariData({'url': 'amikomstudent://notifikasi/123'}),
        '123',
      );
    });

    test('url punya prioritas di atas notif_id', () {
      expect(
        PushService.idDariData({
          'url': 'amikomstudent://notifikasi/11',
          'notif_id': '22',
        }),
        '11',
      );
    });

    test('fallback notif_id — string maupun angka', () {
      expect(PushService.idDariData({'notif_id': '456'}), '456');
      expect(PushService.idDariData({'notif_id': 456}), '456');
    });

    test('skema / url asing tanpa notif_id → null', () {
      expect(
        PushService.idDariData({'url': 'https://contoh/notifikasi/9'}),
        isNull,
      );
      expect(PushService.idDariData({'url': 'mailto://notifikasi/9'}), isNull);
      expect(
        PushService.idDariData({'url': 'amikomstudent://pengumuman/9'}),
        isNull,
      );
      expect(PushService.idDariData({}), isNull);
      expect(PushService.idDariData({'notif_id': '   '}), isNull);
    });

    test('url asing tetapi ada notif_id → pakai notif_id', () {
      expect(
        PushService.idDariData({'url': 'https://x/9', 'notif_id': '77'}),
        '77',
      );
    });
  });

  group('PushService dedupe buka-notifikasi (via DeepLinkService)', () {
    // Id unik per tes: DeepLinkService bersifat singleton dan jendela dedupe
    // 2 detik tidak boleh tertabrak antar-tes. Antrean pending dibersihkan di
    // tearDown seperti pola test/deep_link_service_test.dart.
    tearDown(() {
      DeepLinkService.instance.consumePendingId();
    });

    test('id sama dalam 2 detik hanya diproses sekali', () {
      const data = {'url': 'amikomstudent://notifikasi/9104'};

      expect(PushService.instance.resolveOpenedId(data), '9104');
      expect(
        PushService.instance.resolveOpenedId(data),
        isNull,
        reason: 'duplikat dalam 2 detik harus diabaikan',
      );
    });

    test('url / skema asing tidak membuka apa pun', () {
      expect(
        PushService.instance.resolveOpenedId({'url': 'https://contoh/1'}),
        isNull,
      );
      expect(
        PushService.instance.resolveOpenedId({'url': 'amikomstudent://pengumuman/1'}),
        isNull,
      );
    });

    test('id berbeda yang datang beruntun tetap diproses', () {
      expect(
        PushService.instance.resolveOpenedId({'notif_id': '9105'}),
        '9105',
      );
      expect(
        PushService.instance.resolveOpenedId({'notif_id': '9106'}),
        '9106',
        reason: 'dedupe tidak boleh menelan id yang berbeda',
      );
    });
  });
}
