class MakulBelumValidasi {
  final String kode;
  final String makul;
  final int count;
  final List<String> idPresensiMhs;
  final List<String> kelasgab;

  MakulBelumValidasi({
    required this.kode,
    required this.makul,
    required this.count,
    required this.idPresensiMhs,
    required this.kelasgab,
  });

  factory MakulBelumValidasi.fromJson(MapEntry<String, dynamic> entry) =>
      MakulBelumValidasi(
        kode: entry.key,
        makul: entry.value['makul'] ?? '',
        count: (entry.value['count'] ?? 0).toInt(),
        idPresensiMhs: (entry.value['id_presensi_mhs'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        kelasgab: (entry.value['kelasgab'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class OptionItem {
  final String value;
  final String label;

  OptionItem({required this.value, required this.label});

  factory OptionItem.fromJson(Map<String, dynamic> json) => OptionItem(
        value: json['value'] ?? '',
        label: json['label'] ?? '',
      );
}

class AbsensiMahasiswa {
  final String jenisPerkuliahan;
  final String namaDosen;
  final List<RiwayatPertemuan> riwayatPertemuan;
  final StatistikAbsensi statistik;
  final StatistikAbsensi total;

  AbsensiMahasiswa({
    required this.jenisPerkuliahan,
    required this.namaDosen,
    required this.riwayatPertemuan,
    required this.statistik,
    required this.total,
  });

  factory AbsensiMahasiswa.fromJson(Map<String, dynamic> json) =>
      AbsensiMahasiswa(
        jenisPerkuliahan: json['jenis_perkuliahan'] ?? '',
        namaDosen: json['nama_dosen'] ?? '',
        riwayatPertemuan: (json['riwayat_pertemuan'] as List?)
                ?.map((e) => RiwayatPertemuan.fromJson(e))
                .toList() ??
            [],
        statistik: StatistikAbsensi.fromJson(json['statistik']),
        total: StatistikAbsensi.fromJson(json['total']),
      );
}

class RiwayatPertemuan {
  final String tanggal;
  final String materi;
  final String status;
  final String? idPresensi;

  RiwayatPertemuan({
    required this.tanggal,
    required this.materi,
    required this.status,
    this.idPresensi,
  });

  factory RiwayatPertemuan.fromJson(Map<String, dynamic> json) =>
      RiwayatPertemuan(
        tanggal: json['tanggal'] ?? '',
        materi: json['materi'] ?? '',
        status: json['status'] ?? '',
        idPresensi: json['id_presensi']?.toString(),
      );
}

class StatistikAbsensi {
  final double hadir;
  final double izin;
  final double tanpaKeterangan;
  final double sakit;
  final double belumValidasi;
  final double? kehadiran;

  StatistikAbsensi({
    required this.hadir,
    required this.izin,
    required this.tanpaKeterangan,
    required this.sakit,
    required this.belumValidasi,
    this.kehadiran,
  });

  factory StatistikAbsensi.fromJson(Map<String, dynamic>? json) =>
      StatistikAbsensi(
        hadir: _parseDouble(json?['hadir']),
        izin: _parseDouble(json?['izin']),
        tanpaKeterangan: _parseDouble(json?['tanpa_keterangan']),
        sakit: _parseDouble(json?['sakit']),
        belumValidasi: _parseDouble(json?['belum_validasi']),
        kehadiran: json?['kehadiran'] != null
            ? _parseDouble(json!['kehadiran'])
            : null,
      );

  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class PresensiDetail {
  final String nik;
  final String nama;
  final String tanggal;
  final String judulMateri;
  final String idPresensiMhs;
  final String idPresensiDosen;
  final String keterangan;
  final String jam;
  final String? validasi;
  final String kuliahTpId;
  final List<Kriteria> kriterias;

  PresensiDetail({
    required this.nik,
    required this.nama,
    required this.tanggal,
    required this.judulMateri,
    required this.idPresensiMhs,
    required this.idPresensiDosen,
    required this.keterangan,
    required this.jam,
    this.validasi,
    required this.kuliahTpId,
    required this.kriterias,
  });

  factory PresensiDetail.fromJson(Map<String, dynamic> json) =>
      PresensiDetail(
        nik: json['nik'] ?? '',
        nama: json['nama'] ?? '',
        tanggal: json['tanggal'] ?? '',
        judulMateri: json['judul_materi'] ?? '',
        idPresensiMhs: json['id_presensi_mhs']?.toString() ?? '',
        idPresensiDosen: json['id_presensi_dosen']?.toString() ?? '',
        keterangan: json['keterangan'] ?? '',
        jam: json['jam'] ?? '',
        validasi: json['validasi']?.toString(),
        kuliahTpId: json['kuliah_tp_id']?.toString() ?? '',
        kriterias: (json['kriterias'] as List?)
                ?.map((e) => Kriteria.fromJson(e))
                .toList() ??
            [],
      );
}

class Kriteria {
  final String id;
  final String isi;
  final List<NilaiOption> nilai;

  Kriteria({required this.id, required this.isi, required this.nilai});

  factory Kriteria.fromJson(Map<String, dynamic> json) => Kriteria(
        id: json['asdos_krit_id']?.toString() ?? '',
        isi: json['asdos_krit_isi'] ?? '',
        nilai: (json['nilai'] as List?)
                ?.map((e) => NilaiOption.fromJson(e))
                .toList() ??
            [],
      );
}

class NilaiOption {
  final String id;
  final String isi;
  final int nilai;

  NilaiOption({required this.id, required this.isi, required this.nilai});

  factory NilaiOption.fromJson(Map<String, dynamic> json) => NilaiOption(
        id: json['asdos_krit_nilai_id']?.toString() ?? '',
        isi: json['asdos_krit_nilai_isi'] ?? '',
        nilai: (json['asdos_krit_nilai'] ?? 0).toInt(),
      );
}
