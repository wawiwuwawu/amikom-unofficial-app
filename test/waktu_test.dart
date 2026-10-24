// Test helper waktu bersama (lib/utils/waktu.dart) yang dipakai beranda
// (deteksi "berlangsung"), jadwal (chip jam), dan pengingat jadwal.

import 'package:app_amikom/models/agenda_terpadu.dart';
import 'package:app_amikom/utils/waktu.dart';
import 'package:flutter_test/flutter_test.dart';

AgendaItem _item({String jam = '', String mulai = '', String selesai = ''}) =>
    AgendaItem(
      tipe: 'kuliah',
      hari: 'Senin',
      jam: jam,
      jamMulai: mulai,
      jamSelesai: selesai,
      ruang: '',
      matakuliah: 'X',
      detail: '',
    );

void main() {
  group('timeToMinutes', () {
    test('format ":" biasa', () {
      expect(timeToMinutes('08:30'), 8 * 60 + 30);
      expect(timeToMinutes('09:00'), 540);
    });

    test('format "." dari portal tetap terbaca', () {
      expect(timeToMinutes('08.30'), 8 * 60 + 30);
      expect(timeToMinutes('10.40'), 10 * 60 + 40);
    });

    test('tidak bisa diparse → 0', () {
      expect(timeToMinutes(''), 0);
      expect(timeToMinutes('abc'), 0);
    });

    test("'hh:mm:ss' hanya membaca dua bagian pertama (perilaku dashboard lama)", () {
      expect(timeToMinutes('12:30:00'), 12 * 60 + 30);
    });
  });

  group('ongoingRange', () {
    test('jam_mulai/jam_selesai menang bila keduanya terisi', () {
      final r = ongoingRange(_item(
        jam: '08:00 - 09:40',
        mulai: '10:40',
        selesai: '12:20',
      ));
      expect(r, (10 * 60 + 40, 12 * 60 + 20));
    });

    test('fallback parsing jam "hh:mm - hh:mm"', () {
      final r = ongoingRange(_item(jam: '10:40 - 12:20'));
      expect(r, (10 * 60 + 40, 12 * 60 + 20));
    });

    test("jam '.' tetap terbaca lewat fallback", () {
      final r = ongoingRange(_item(jam: '08.30 - 10.10'));
      expect(r, (8 * 60 + 30, 10 * 60 + 10));
    });

    test('marker kosong "-" → null', () {
      expect(ongoingRange(_item(jam: '-')), isNull);
    });

    test('tanpa jam sama sekali → null', () {
      expect(ongoingRange(_item()), isNull);
    });

    test('jam tanpa tanda "-" tidak bisa jadi rentang', () {
      expect(ongoingRange(_item(jam: '12:30:00')), isNull);
    });
  });

  group('jamChip', () {
    test('jam_mulai menang bila terisi', () {
      expect(jamChip(_item(jam: '08:00 - 09:40', mulai: '10:40')), '10:40');
    });

    test("marker kosong '-' jatuh ke jam warisan", () {
      expect(jamChip(_item(jam: '08:00 - 09:40', mulai: '-')), '08:00 - 09:40');
    });

    test('dua-duanya kosong / "-" → "-"', () {
      expect(jamChip(_item()), '-');
      expect(jamChip(_item(jam: '-')), '-');
    });
  });

  group('namaHariDariWeekday', () {
    test('pemetaan lengkap selaras dayValue (Senin=1..Minggu=7)', () {
      expect(namaHariDariWeekday(DateTime.monday), 'Senin');
      expect(namaHariDariWeekday(DateTime.tuesday), 'Selasa');
      expect(namaHariDariWeekday(DateTime.wednesday), 'Rabu');
      expect(namaHariDariWeekday(DateTime.thursday), 'Kamis');
      expect(namaHariDariWeekday(DateTime.friday), 'Jumat');
      expect(namaHariDariWeekday(DateTime.saturday), 'Sabtu');
      expect(namaHariDariWeekday(DateTime.sunday), 'Minggu');
    });

    test('nilai di luar 1-7 fallback aman', () {
      expect(namaHariDariWeekday(0), 'Senin');
    });
  });
}
