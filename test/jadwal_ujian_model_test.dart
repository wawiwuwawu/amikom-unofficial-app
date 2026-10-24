// Test model JadwalUjian: key tanggal portal berbeda antara UTS (`TANGGAL`)
// dan UAS (`TGL_UJIAN`) — keduanya harus terbaca (alias key sederhana, BE akan
// menyeragamkan — lihat pesan-be.md). Tanpa alias, tanggal UAS kosong dan
// gerbang/periode/pengingat ujian buta tanggal.

import 'package:app_amikom/models/jadwal_ujian.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UTS membaca key TANGGAL', () {
    final u = JadwalUjian.fromJson({
      'KODE': 'TIF123',
      'MKL': 'Basis Data',
      'TANGGAL': '08-07-2026',
      'HARI': 'Rabu',
      'RUANG': 'AULA',
      'JAM_MULAI': '08:00',
      'JAM_SELESEI': '09:40',
      'NOKURSI': 12,
    });
    expect(u.tanggal, '08-07-2026');
  });

  test('UAS membaca key TGL_UJIAN (alias)', () {
    final u = JadwalUjian.fromJson({
      'KODE': 'TIF456',
      'MKL': 'Jaringan Komputer',
      'TGL_UJIAN': '20-12-2026',
      'HARI': 'Senin',
      'RUANG': 'LT2',
      'JAM_MULAI': '13:00',
      'JAM_SELESEI': '14:40',
      'NOKURSI': 7,
    });
    expect(u.tanggal, '20-12-2026');
  });

  test('tanpa keduanya → tanggal kosong (bukan galat)', () {
    final u = JadwalUjian.fromJson({'KODE': 'X', 'MKL': 'Y'});
    expect(u.tanggal, '');
  });
}
