// Test kontrak model Biodata (GET /api/v1/biodata) — pola §8.2:
// kosong "" & NULL dinormalisasi, nested {kode,label} memakai label,
// submodel tak dikenal (null/bentuk lain) → fallback aman, tanpa lempar.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_amikom/models/biodata.dart';

Map<String, dynamic> _payload({
  String tanggalLahir = '2005-12-07',
  bool kosongkanSemua = false,
}) {
  final t = kosongkanSemua ? '' : tanggalLahir;
  String s(String v) => kosongkanSemua ? '' : v;
  return {
    'data_diri': {
      'nama': s('Wawan Setiawan'),
      'nikktp': s('3301010512070001'),
      'tempat_lahir': s('Purwokerto'),
      'tanggal_lahir': t,
      'jenis_kelamin': {'kode': 'L', 'label': s('Laki-laki')},
      'agama': {'kode': 'I', 'label': s('Islam')},
      'status_perkawinan': s('Belum Menikah'),
      'jumlah_anak': '',
      'email': s('wawan@student.amikom.ac.id'),
      'no_hp': s('081234567890'),
      'nisn': '',
    },
    'alamat': {
      'alamat': s('Jl. Jend. Sudirman No. 1'),
      'rt': s('02'),
      'rw': s('05'),
      'kecamatan': s('Kembaran'),
      'kabupaten': s('Banyumas'),
      'propinsi': s('Jawa Tengah'),
      'kode_pos': s('53182'),
    },
    'pendidikan': {
      'sd': {
        'nama': s('SD Negeri 1'),
        'kabupaten': s('Banyumas'),
        'propinsi': s('Jawa Tengah'),
        'tahun_lulus': s('2018'),
      },
      'smp': {
        'nama': s('SMP Negeri 2'),
        'kabupaten': s('Banyumas'),
        'propinsi': s('Jawa Tengah'),
        'tahun_lulus': s('2021'),
      },
      'sma': {
        'nama': s('SMA Negeri 3'),
        'kabupaten': s('Banyumas'),
        'propinsi': s('Jawa Tengah'),
        'tahun_lulus': s('2024'),
      },
    },
    'orang_tua': {
      'ayah': {
        'nama': s('Sugiyanto'),
        'alamat': s('Jl. Melati No. 3'),
        'rt': s('02'),
        'rw': s('05'),
        'kecamatan': s('Kembaran'),
        'kabupaten': s('Banyumas'),
        'propinsi': s('Jawa Tengah'),
        'kode_pos': s('53182'),
        'pendidikan': s('SMA'),
        'pekerjaan': s('Wiraswasta'),
        'pekerjaan_lainnya': '',
        'status': s('Masih Hidup'),
        'no_hp': s('081200000001'),
        'nip_nrp': '',
        'pangkat': '',
        'jabatan': s('Pemilik Toko'),
        'instansi': s('Toko Barokah'),
      },
      'ibu': {
        'nama': s('Sri Wahyuni'),
        'pendidikan': s('SMA'),
        'pekerjaan': s('Ibu Rumah Tangga'),
        'status': s('Masih Hidup'),
        'no_hp': s('081200000002'),
        'instansi': '',
      },
    },
    'foto_url': s('https://portal.amikom.ac.id/foto/23sa21a060.jpg'),
  };
}

void main() {
  group('Biodata.fromJson — parse lengkap', () {
    final b = Biodata.fromJson(_payload());

    test('data diri terparse', () {
      expect(b.dataDiri.nama, 'Wawan Setiawan');
      expect(b.dataDiri.nikktp, '3301010512070001');
      expect(b.dataDiri.tempatLahir, 'Purwokerto');
      expect(b.dataDiri.tanggalLahir, '2005-12-07');
      expect(b.dataDiri.statusPerkawinan, 'Belum Menikah');
      expect(b.dataDiri.email, 'wawan@student.amikom.ac.id');
      expect(b.dataDiri.noHp, '081234567890');
    });

    test('jenis kelamin & agama memakai LABEL (bukan kode)', () {
      expect(b.dataDiri.jenisKelamin.label, 'Laki-laki');
      expect(b.dataDiri.jenisKelamin.kode, 'L');
      expect(b.dataDiri.agama.label, 'Islam');
    });

    test('alamat terparse', () {
      expect(b.alamat.alamat, 'Jl. Jend. Sudirman No. 1');
      expect(b.alamat.rt, '02');
      expect(b.alamat.rw, '05');
      expect(b.alamat.kecamatan, 'Kembaran');
      expect(b.alamat.kabupaten, 'Banyumas');
      expect(b.alamat.propinsi, 'Jawa Tengah');
      expect(b.alamat.kodePos, '53182');
    });

    test('pendidikan sd/smp/sma terparse', () {
      expect(b.pendidikan.sd.nama, 'SD Negeri 1');
      expect(b.pendidikan.sd.tahunLulus, '2018');
      expect(b.pendidikan.smp.nama, 'SMP Negeri 2');
      expect(b.pendidikan.sma.nama, 'SMA Negeri 3');
      expect(b.pendidikan.sma.tahunLulus, '2024');
    });

    test('orang tua ayah & ibu terparse (satu class dipakai 2x)', () {
      expect(b.orangTua.ayah.nama, 'Sugiyanto');
      expect(b.orangTua.ayah.pekerjaan, 'Wiraswasta');
      expect(b.orangTua.ayah.instansi, 'Toko Barokah');
      expect(b.orangTua.ibu.nama, 'Sri Wahyuni');
      expect(b.orangTua.ibu.pekerjaan, 'Ibu Rumah Tangga');
    });

    test('foto_url terparse', () {
      expect(b.fotoUrl, 'https://portal.amikom.ac.id/foto/23sa21a060.jpg');
    });
  });

  group('Biodata.fromJson — nilai kosong & NULL (kontrak tampil "-")', () {
    test('semua field kosong → string kosong, tanggal_lahir → null', () {
      final b = Biodata.fromJson(_payload(kosongkanSemua: true));
      expect(b.dataDiri.nama, '');
      expect(b.dataDiri.nikktp, '');
      expect(b.dataDiri.tanggalLahir, isNull,
          reason: 'NULL & "" dinormalisasi ke null — penyaji cukup cek null');
      expect(b.fotoUrl, '');
      expect(b.orangTua.ibu.instansi, '');
    });

    test('tanggal_lahir null JSON → null', () {
      // jsonDecode → Map<String, dynamic> dinamis (aman menampung null).
      final raw =
          jsonDecode(jsonEncode(_payload())) as Map<String, dynamic>;
      (raw['data_diri'] as Map)['tanggal_lahir'] = null;
      final b = Biodata.fromJson(raw);
      expect(b.dataDiri.tanggalLahir, isNull);
    });
  });

  group('Biodata.fromJson — ketahanan bentuk tak dikenal', () {
    test('submodel null/absen → fallback aman tanpa lempar', () {
      final b = Biodata.fromJson(jsonDecode(jsonEncode({
        'data_diri': {'nama': 'A'},
      })) as Map<String, dynamic>);
      expect(b.dataDiri.nama, 'A');
      expect(b.dataDiri.tanggalLahir, isNull);
      expect(b.dataDiri.jenisKelamin.label, '');
      expect(b.alamat.alamat, '');
      expect(b.pendidikan.sd.nama, '');
      expect(b.orangTua.ayah.nama, '');
      expect(b.orangTua.ibu.nama, '');
    });

    test('jenis_kelamin string langsung → label tetap terbaca', () {
      final raw =
          jsonDecode(jsonEncode(_payload())) as Map<String, dynamic>;
      (raw['data_diri'] as Map)['jenis_kelamin'] = 'Laki-laki';
      final b = Biodata.fromJson(raw);
      expect(b.dataDiri.jenisKelamin.label, 'Laki-laki');
    });
  });
}
