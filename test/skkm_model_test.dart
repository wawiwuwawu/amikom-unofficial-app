// Regresi model SKKM: parsing kontrak BE 2026-11-01 §4 — field opsional
// (bukti, id_aktivitas, komentar_validator) bisa absen; `status` string apa
// adanya; angkatan < 2024 → skkm_berlaku false + poin null BUKAN galat.

import 'package:app_amikom/models/skkm.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _aktivitasJson() => {
      'no': 1,
      'nim': '25SA31A037',
      'nama': 'ZULVIKAR ABBITAH INDRA RIFKIANTO',
      'kegiatan': {
        'unsur': 'Kegiatan Penalaran dan Pengembangan Ilmu',
        'sub_unsur': 'Mengikuti Pelatihan / Workshop Sebagai Peserta',
        'level': 'Regional',
        'jenis_keg': 'individu',
        'role': 'Sebagai ketua',
        'jml_anggota': 0,
        'surat_tugas': '1824/AMIKOMPWT/DAKK.2/06/I/2026',
      },
      'bukti': {'id': '1791', 'url': 'https://portal/skkm/previewBukti?id=1791'},
      'diupload_oleh': 'Mahasiswa',
      'kredit': 10,
      'status': 'Valid',
      'validator': 'PRODI',
    };

void main() {
  test('parse contoh kontrak lengkap dari panduan BE', () {
    final data = SkkmData.fromJson({
      'angkatan': 2025,
      'skkm_berlaku': true,
      'total_poin_valid': 55,
      'panduan_url': 'https://portal/file_upload/Panduan_SKKM.pdf',
      'jumlah_aktivitas': 5,
      'opsi_unsur': [
        {'value': '1', 'label': 'Kegiatan Penalaran dan Pengembangan Ilmu'},
        {'value': '2', 'label': 'Kegiatan Kepemimpinan'},
      ],
      'aktivitas': [_aktivitasJson()],
    });

    expect(data.angkatan, 2025);
    expect(data.skkmBerlaku, isTrue);
    expect(data.totalPoinValid, 55);
    expect(data.jumlahAktivitas, 5);
    expect(data.opsiUnsur.length, 2);
    expect(data.opsiUnsur[0].value, '1');
    expect(data.opsiUnsur[0].label, 'Kegiatan Penalaran dan Pengembangan Ilmu');

    final item = data.aktivitas.single;
    expect(item.no, 1);
    expect(item.subUnsur, 'Mengikuti Pelatihan / Workshop Sebagai Peserta');
    expect(item.level, 'Regional');
    expect(item.jenisKeg, 'individu');
    expect(item.role, 'Sebagai ketua');
    expect(item.suratTugas, '1824/AMIKOMPWT/DAKK.2/06/I/2026');
    expect(item.bukti?.id, '1791');
    expect(item.kredit, 10);
    expect(item.status, 'Valid');
    expect(item.validator, 'PRODI');
    expect(item.idAktivitas, isNull);
    expect(item.komentarValidator, isNull);
  });

  test('baris Tidak Valid membawa id_aktivitas + komentar validator', () {
    final json = _aktivitasJson()
      ..['status'] = 'Tidak Valid'
      ..['validator'] = 'KEMAHASISWAAN'
      ..['id_aktivitas'] = '1801'
      ..['komentar_validator'] = 'Bukti fisik tidak terbaca. Upload ulang.'
      ..['bukti'] = null;

    final item = SkkmAktivitas.fromJson(json);
    expect(item.status, 'Tidak Valid');
    expect(item.idAktivitas, '1801');
    expect(item.komentarValidator, contains('tidak terbaca'));
    expect(item.bukti, isNull);
  });

  test('angkatan < 2024: skkm_berlaku false, poin null, aktivitas kosong',
      () {
    final data = SkkmData.fromJson({
      'angkatan': 2023,
      'skkm_berlaku': false,
      'total_poin_valid': null,
      'panduan_url': '',
      'jumlah_aktivitas': 0,
      'aktivitas': [],
    });

    expect(data.skkmBerlaku, isFalse);
    expect(data.totalPoinValid, isNull);
    expect(data.aktivitas, isEmpty);
    expect(data.opsiUnsur, isEmpty,
        reason: 'opsi_unsur tidak dikirim saat tidak berlaku');
  });

  test('field numerik berbentuk string tetap terparse (portal longgar)', () {
    final data = SkkmData.fromJson({
      'angkatan': '2025',
      'skkm_berlaku': 'true',
      'total_poin_valid': '55',
      'jumlah_aktivitas': '2',
      'aktivitas': [_aktivitasJson()..['kredit'] = '10'],
    });

    expect(data.angkatan, 2025);
    expect(data.skkmBerlaku, isTrue);
    expect(data.totalPoinValid, 55);
    expect(data.jumlahAktivitas, 2);
    expect(data.aktivitas.single.kredit, 10);
  });

  test('SkkmKredit membaca kredit + id_skkm untuk dikirim balik', () {
    final k = SkkmKredit.fromJson({'kredit': 10, 'id_skkm': '45'});
    expect(k.kredit, 10);
    expect(k.idSkkm, '45');
  });
}
