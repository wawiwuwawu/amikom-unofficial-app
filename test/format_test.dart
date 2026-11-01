// Test helper format bersama (lib/utils/format.dart).

import 'package:app_amikom/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dayValue', () {
    test('hari biasa Senin … Minggu berurutan 1 … 7', () {
      const hari = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      expect([for (final h in hari) dayValue(h)], [1, 2, 3, 4, 5, 6, 7]);
    });

    test('tidak peka huruf besar dan spasi di tepi', () {
      expect(dayValue('SENIN'), 1);
      expect(dayValue('  kamis \n'), 4);
    });

    test("Jum'at dengan apostrof apa pun tetap hari Jumat", () {
      for (final h in [
        "Jum'at",
        'Jum\u2019at', // kutip tunggal kanan (curly)
        'Jum\u2018at', // kutip tunggal kiri
        'Jum`at',
        'Jum\u00b4at', // aksen akut
        'Jum\u02bcat', // modifier letter apostrophe
        "JUM'AT",
        ' jumat ',
      ]) {
        expect(dayValue(h), 5, reason: h);
      }
    });

    test('bucket khusus Lainnya (8) dan Tanpa Jadwal (9)', () {
      expect(dayValue('Lainnya'), 8);
      expect(dayValue('Tanpa Jadwal'), 9);
      expect(dayValue(' tanpa jadwal '), 9);
    });

    test('nilai tak dikenal masuk Lainnya (8)', () {
      expect(dayValue(''), 8);
      expect(dayValue('Ahad'), 8);
      expect(dayValue('Monday'), 8);
    });
  });

  group('agendaDayLabel', () {
    test('Tanpa Jadwal diganti label tampilan', () {
      expect(agendaDayLabel('Tanpa Jadwal'), 'Belum ada jadwal');
      expect(agendaDayLabel(' tanpa jadwal '), 'Belum ada jadwal');
    });

    test('hari biasa apa adanya', () {
      expect(agendaDayLabel('Senin'), 'Senin');
      expect(agendaDayLabel('Jum\u2019at'), 'Jum\u2019at');
    });
  });

  group('formatRupiah', () {
    test('tanpa desimal dengan pemisah ribuan titik', () {
      expect(formatRupiah(1500000), 'Rp 1.500.000');
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(999), 'Rp 999');
    });
  });

  group('semesterLabel', () {
    test('1 Ganjil, 2 Genap, selain itu nomor semester', () {
      expect(semesterLabel(1), 'Ganjil');
      expect(semesterLabel(2), 'Genap');
      expect(semesterLabel(3), 'Semester 3');
    });
  });

  group('formatDateApi', () {
    test('yyyy-MM-dd dengan nol di depan', () {
      expect(formatDateApi(DateTime(2026, 3, 5)), '2026-03-05');
      expect(formatDateApi(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('formatDateDisplay', () {
    test('d/M/yyyy tanpa nol di depan', () {
      expect(formatDateDisplay(DateTime(2026, 3, 5)), '5/3/2026');
      expect(formatDateDisplay(DateTime(2026, 12, 31)), '31/12/2026');
    });
  });

  group('yearOptions', () {
    test('lima tahun, mulai tahun berjalan lalu mundur', () {
      final now = DateTime.now().year;
      expect(yearOptions(), [now, now - 1, now - 2, now - 3, now - 4]);
    });
  });
}
