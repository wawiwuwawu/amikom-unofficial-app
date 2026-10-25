// Test PeriodeUjianService (kini helper MURNI tanpa fetch — sumber tanggal
// ujian adalah field `tanggal` baris agenda terpadu dari BE): gerbang jendela
// tampil per-baris [dalamJendela], pencari periode terdekat
// [periodeBerikutnya], dan parser tanggal dua-format [tanggalDariPortal].

import 'package:app_amikom/models/agenda_terpadu.dart';
import 'package:app_amikom/services/periode_ujian_service.dart';
import 'package:app_amikom/utils/waktu.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _hariIni() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _iso(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

String _ddmmyyyy(DateTime t) {
  final d = t.day.toString().padLeft(2, '0');
  final m = t.month.toString().padLeft(2, '0');
  return '$d-$m-${t.year}';
}

Map<String, dynamic> _barisUjian({String tipe = 'uts', String? tanggal}) => {
  'tipe': tipe,
  'hari': 'Senin',
  'jam': '08:00 - 10:00',
  'jam_mulai': '08:00',
  'ruang': 'LT2',
  'matakuliah': 'Basis Data',
  'detail': '',
  'tanggal': ?tanggal,
};

AgendaTerpaduData _agenda(Map<String, List<Map<String, dynamic>>> hari) =>
    AgendaTerpaduData.fromJson({
      'total_agenda': hari.values.fold(0, (s, l) => s + l.length),
      'agenda': hari,
    });

void main() {
  group('dalamJendela (gerbang per-baris)', () {
    test('tanggal null → fail-open (tampil)', () {
      expect(PeriodeUjianService.dalamJendela(null, _hariIni()), isTrue);
    });

    test('hari ini dan dalam ambang 7 hari → tampil', () {
      final hari = _hariIni();
      expect(PeriodeUjianService.dalamJendela(hari, hari), isTrue);
      expect(
        PeriodeUjianService.dalamJendela(
          hari.add(const Duration(days: 6)),
          hari,
        ),
        isTrue,
      );
    });

    test('lewat dari ambang / sudah lewat → tidak tampil', () {
      final hari = _hariIni();
      expect(
        PeriodeUjianService.dalamJendela(
          hari.add(const Duration(days: 7)),
          hari,
        ),
        isFalse,
      );
      expect(
        PeriodeUjianService.dalamJendela(
          hari.subtract(const Duration(days: 1)),
          hari,
        ),
        isFalse,
      );
    });
  });

  group('periodeBerikutnya (pure, dari baris agenda)', () {
    test('pilih ujian terdekat ≥ hari ini dari uts & uas', () {
      final hari = _hariIni();
      final data = _agenda({
        'Senin': [
          _barisUjian(
            tipe: 'uts',
            tanggal: _iso(hari.add(const Duration(days: 10))),
          ),
          _barisUjian(
            tipe: 'uas',
            tanggal: _iso(hari.add(const Duration(days: 3))),
          ),
        ],
      });

      final hasil = PeriodeUjianService.periodeBerikutnya(data, hari);

      expect(hasil, isNotNull);
      expect(hasil!.$1, hari.add(const Duration(days: 3)));
      expect(hasil.$2, 'UAS');
    });

    test('ujian lewat, tanpa tanggal, dan non-ujian diabaikan', () {
      final hari = _hariIni();
      final data = _agenda({
        'Senin': [
          _barisUjian(
            tipe: 'uts',
            tanggal: _iso(hari.subtract(const Duration(days: 2))),
          ),
          _barisUjian(tipe: 'uas'), // respons lama: tanpa tanggal
          {
            'tipe': 'kuliah',
            'hari': 'Senin',
            'jam': '08:00 - 09:40',
            'jam_mulai': '08:00',
            'ruang': 'D.3.J',
            'matakuliah': 'Pemrograman Mobile',
            'detail': '',
          },
        ],
      });

      expect(PeriodeUjianService.periodeBerikutnya(data, hari), isNull);
    });

    test('format warisan dd-MM-yyyy tetap terbaca', () {
      final hari = _hariIni();
      final dekat = hari.add(const Duration(days: 2));
      final data = _agenda({
        'Senin': [_barisUjian(tipe: 'uas', tanggal: _ddmmyyyy(dekat))],
      });

      final hasil = PeriodeUjianService.periodeBerikutnya(data, hari);

      expect(hasil!.$1, dekat);
      expect(hasil.$2, 'UAS');
    });
  });

  group('parser tanggalDariPortal (dua format per perjanjian BE)', () {
    test('yyyy-MM-dd (format seragam baru BE) valid', () {
      expect(tanggalDariPortal('2026-11-24'), DateTime(2026, 11, 24));
      expect(tanggalDariPortal('2026-07-08'), DateTime(2026, 7, 8));
    });

    test('dd-MM-yyyy (format warisan portal) valid', () {
      expect(tanggalDariPortal('08-07-2026'), DateTime(2026, 7, 8));
      expect(tanggalDariPortal('24-11-2026'), DateTime(2026, 11, 24));
    });

    test('tidak valid / tidak valid kalender → null', () {
      expect(tanggalDariPortal(''), isNull);
      expect(tanggalDariPortal('32-13-2026'), isNull);
      expect(tanggalDariPortal('2026-13-01'), isNull);
      expect(tanggalDariPortal('2026-02-30'), isNull);
      expect(tanggalDariPortal('abc'), isNull);
      expect(tanggalDariPortal('belum diumumkan'), isNull);
    });

    test('formatTanggalIndo memakai nama bulan Indonesia', () {
      expect(formatTanggalIndo(DateTime(2026, 11, 24)), '24 November 2026');
    });
  });
}
