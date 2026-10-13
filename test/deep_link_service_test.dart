import 'package:app_amikom/services/deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkService.extractNotifId', () {
    test('mengembalikan id untuk URI notifikasi yang valid', () {
      final uri = Uri.parse('amikomstudent://notifikasi/4201');
      expect(DeepLinkService.extractNotifId(uri), '4201');
    });

    test('tidak peka huruf besar/kecil pada scheme dan host', () {
      final uri = Uri.parse('AMIKOMSTUDENT://NOTIFIKASI/9876');
      expect(DeepLinkService.extractNotifId(uri), '9876');
    });

    test('mengembalikan string kosong untuk scheme atau host lain', () {
      expect(
        DeepLinkService.extractNotifId(Uri.parse('https://notifikasi/4201')),
        '',
      );
      expect(
        DeepLinkService.extractNotifId(Uri.parse('mailto://notifikasi/4201')),
        '',
      );
      expect(
        DeepLinkService.extractNotifId(
          Uri.parse('amikomstudent://pengumuman/4201'),
        ),
        '',
      );
      expect(
        DeepLinkService.extractNotifId(Uri.parse('amikomstudent:///4201')),
        '',
      );
    });

    test('mengembalikan string kosong bila tanpa path atau path kosong', () {
      expect(
        DeepLinkService.extractNotifId(Uri.parse('amikomstudent://notifikasi')),
        '',
      );
      expect(
        DeepLinkService.extractNotifId(
          Uri.parse('amikomstudent://notifikasi/'),
        ),
        '',
      );
      expect(
        DeepLinkService.extractNotifId(
          Uri.parse('amikomstudent://notifikasi///'),
        ),
        '',
      );
      expect(
        DeepLinkService.extractNotifId(
          Uri.parse('amikomstudent://notifikasi/%20/'),
        ),
        '',
      );
    });

    test(
      'menangani path multi-segmen dan karakter aneh secara wajar tanpa melempar',
      () {
        expect(
          DeepLinkService.extractNotifId(
            Uri.parse('amikomstudent://notifikasi/4201/detail/lampiran'),
          ),
          '4201',
        );
        expect(
          DeepLinkService.extractNotifId(
            Uri.parse('amikomstudent://notifikasi//4201/'),
          ),
          '4201',
        );
        expect(
          DeepLinkService.extractNotifId(
            Uri.parse('amikomstudent://notifikasi/4201?utm_source=push#isi'),
          ),
          '4201',
        );
        expect(
          DeepLinkService.extractNotifId(
            Uri.parse('amikomstudent://notifikasi/notif_2026-10~abc%21'),
          ),
          'notif_2026-10~abc!',
        );
      },
    );
  });

  group('DeepLinkService.handleUri & antrean pending', () {
    // Id unik per tes: instance bersifat singleton, jadi jendela dedupe 2 detik
    // tidak boleh tertabrak antar-tes.
    tearDown(() {
      DeepLinkService.instance.consumePendingId();
    });

    test('memproses tautan milik kita dan mengabaikan yang lain', () {
      final service = DeepLinkService.instance;

      expect(
        service.handleUri(Uri.parse('amikomstudent://notifikasi/5001')),
        '5001',
      );
      expect(service.handleUri(Uri.parse('https://example.com/5001')), isNull);
      expect(
        service.handleUri(Uri.parse('amikomstudent://pengumuman/5001')),
        isNull,
      );
    });

    test('tautan identik dalam jendela dedupe hanya diproses sekali', () {
      final service = DeepLinkService.instance;

      expect(
        service.handleUri(Uri.parse('amikomstudent://notifikasi/5002')),
        '5002',
      );
      expect(
        service.handleUri(Uri.parse('amikomstudent://notifikasi/5002')),
        isNull,
        reason: 'duplikat dalam 2 detik harus diabaikan',
      );
    });

    test('tautan berbeda yang datang beruntun tetap diproses', () {
      final service = DeepLinkService.instance;

      expect(
        service.handleUri(Uri.parse('amikomstudent://notifikasi/5003')),
        '5003',
      );
      expect(
        service.handleUri(Uri.parse('amikomstudent://notifikasi/5004')),
        '5004',
        reason: 'dedupe tidak boleh menelan id yang berbeda',
      );
    });

    test('tautan awal yang sudah diproses stream tidak dibuka dobel', () {
      final service = DeepLinkService.instance;
      service.seedPendingUri(Uri.parse('amikomstudent://notifikasi/5005'));

      expect(
        service.handleUri(Uri.parse('amikomstudent://notifikasi/5005')),
        '5005',
      );
      expect(
        service.consumePendingId(),
        isNull,
        reason: 'pending yang sudah diproses stream tidak boleh dibuka lagi',
      );
    });

    test('tautan awal yang belum diproses stream tetap bisa dikonsumsi', () {
      final service = DeepLinkService.instance;
      service.seedPendingUri(Uri.parse('amikomstudent://notifikasi/5006'));

      expect(service.consumePendingId(), '5006');
      expect(
        service.consumePendingId(),
        isNull,
        reason: 'pending hanya boleh dikonsumsi sekali',
      );
    });

    test('seedPendingUri mengabaikan tautan yang bukan milik kita', () {
      final service = DeepLinkService.instance;
      service.seedPendingUri(Uri.parse('https://example.com/5007'));
      service.seedPendingUri(null);

      expect(service.consumePendingId(), isNull);
    });
  });
}
