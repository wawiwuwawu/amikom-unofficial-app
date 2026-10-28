// Unit PeriodeKrsData (kontrak BE §2.3): parsing fail-open + kunci periode
// untuk penutupan banner per-periode + label rentang ramah-baca.

import 'package:app_amikom/services/periode_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeriodeKrsData.fromJson', () {
    test('dibuka + tanggal ISO utuh', () {
      final d = PeriodeKrsData.fromJson({
        'dibuka': true,
        'mulai': '2026-11-02',
        'selesai': '2026-11-07',
      });
      expect(d.dibuka, isTrue);
      expect(d.kunci, '2026-11-02..2026-11-07');
      expect(d.labelRentang, '2 November 2026 – 7 November 2026');
    });

    test('tanggal null / teks tak-parse → fail-open tanpa melempar', () {
      final d = PeriodeKrsData.fromJson({
        'dibuka': false,
        'mulai': null,
        'selesai': null,
      });
      expect(d.dibuka, isFalse);
      expect(d.kunci, 'null..null');
      expect(d.labelRentang, isNull);
    });

    test('string kosong diperlakukan null', () {
      final d = PeriodeKrsData.fromJson({
        'dibuka': true,
        'mulai': '',
        'selesai': '',
      });
      expect(d.labelRentang, isNull);
    });
  });
}
