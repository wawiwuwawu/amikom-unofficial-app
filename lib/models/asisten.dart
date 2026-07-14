class AsistenMahasiswa {
  final String npm;
  final String nama;
  final String koda;
  final String namaDept;
  final String pa;

  AsistenMahasiswa({
    required this.npm,
    required this.nama,
    required this.koda,
    required this.namaDept,
    required this.pa,
  });

  factory AsistenMahasiswa.fromJson(Map<String, dynamic> json) {
    return AsistenMahasiswa(
      npm: json['npm'] ?? '',
      nama: json['NAMA'] ?? '',
      koda: json['koda'] ?? '',
      namaDept: json['nama_dept'] ?? '',
      pa: json['pa'] ?? '',
    );
  }
}

class AsistenStats {
  final int hadir;
  final int izin;
  final int pengganti;
  final int alpa;
  final double rataRataMhs;

  AsistenStats({
    required this.hadir,
    required this.izin,
    required this.pengganti,
    required this.alpa,
    required this.rataRataMhs,
  });

  factory AsistenStats.fromJson(Map<String, dynamic> json) {
    return AsistenStats(
      hadir: json['hadir'] ?? 0,
      izin: json['izin'] ?? 0,
      pengganti: json['pengganti'] ?? 0,
      alpa: json['alpa'] ?? 0,
      rataRataMhs: (json['rataRataMhs'] ?? 0).toDouble(),
    );
  }
}

class AsistenAturan {
  final int totalPresensi;
  final double rataRata;

  AsistenAturan({
    required this.totalPresensi,
    required this.rataRata,
  });

  factory AsistenAturan.fromJson(Map<String, dynamic> json) {
    return AsistenAturan(
      totalPresensi: json['total_presensi'] ?? 0,
      rataRata: (json['rata_rata'] ?? 0).toDouble(),
    );
  }
}

class AsistenInfo {
  final AsistenMahasiswa mahasiswa;
  final AsistenStats stats;
  final AsistenAturan aturan;
  final bool bisaAjukanBebasKP;

  AsistenInfo({
    required this.mahasiswa,
    required this.stats,
    required this.aturan,
    required this.bisaAjukanBebasKP,
  });

  factory AsistenInfo.fromJson(Map<String, dynamic> json) {
    return AsistenInfo(
      mahasiswa: AsistenMahasiswa.fromJson(json['mahasiswa'] ?? {}),
      stats: AsistenStats.fromJson(json['stats'] ?? {}),
      aturan: AsistenAturan.fromJson(json['aturan'] ?? {}),
      bisaAjukanBebasKP: json['bisaAjukanBebasKP'] ?? false,
    );
  }
}

class AsistenTahunAkademik {
  final int idTahun;
  final String thnAkademik;
  final int semester;

  AsistenTahunAkademik({
    required this.idTahun,
    required this.thnAkademik,
    required this.semester,
  });

  factory AsistenTahunAkademik.fromJson(Map<String, dynamic> json) {
    return AsistenTahunAkademik(
      idTahun: json['ID_TAHUN'] ?? 0,
      thnAkademik: json['THN_AKADEMIK'] ?? '',
      semester: json['SEMESTER'] ?? 0,
    );
  }
}

class AsistenTahunAkademikResponse {
  final List<AsistenTahunAkademik> data;

  AsistenTahunAkademikResponse({required this.data});

  factory AsistenTahunAkademikResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    return AsistenTahunAkademikResponse(
      data: list.map((e) => AsistenTahunAkademik.fromJson(e)).toList(),
    );
  }
}

class AsistenJadwal {
  final String kode;
  final String mkl;
  final String dosen;
  final int sks;
  final String thnAjaran;
  final String hari;
  final String ruang;
  final String jam;

  AsistenJadwal({
    required this.kode,
    required this.mkl,
    required this.dosen,
    required this.sks,
    required this.thnAjaran,
    required this.hari,
    required this.ruang,
    required this.jam,
  });

  factory AsistenJadwal.fromJson(Map<String, dynamic> json) {
    return AsistenJadwal(
      kode: json['KODE'] ?? '',
      mkl: json['MKL'] ?? '',
      dosen: json['dosen'] ?? '',
      sks: json['sks'] ?? 0,
      thnAjaran: json['thn_ajaran'] ?? '',
      hari: json['hari'] ?? '',
      ruang: json['ruang'] ?? '',
      jam: json['jam'] ?? '',
    );
  }
}

class AsistenJadwalResponse {
  final List<AsistenJadwal> data;
  final int jumlah;
  final int jumlahPage;

  AsistenJadwalResponse({
    required this.data,
    required this.jumlah,
    required this.jumlahPage,
  });

  factory AsistenJadwalResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    return AsistenJadwalResponse(
      data: list.map((e) => AsistenJadwal.fromJson(e)).toList(),
      jumlah: json['jumlah'] ?? 0,
      jumlahPage: json['jumlahPage'] ?? 0,
    );
  }
}

class AsistenDataset {
  final String type;
  final String label;
  final String borderColor;
  final List<double> data;

  AsistenDataset({
    required this.type,
    required this.label,
    required this.borderColor,
    required this.data,
  });

  factory AsistenDataset.fromJson(Map<String, dynamic> json) {
    var rawData = json['data'] as List? ?? [];
    return AsistenDataset(
      type: json['type'] ?? '',
      label: json['label'] ?? '',
      borderColor: json['borderColor'] ?? '',
      data: rawData.map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class AsistenLaporan {
  final List<String> labels;
  final List<AsistenDataset> datasets;

  AsistenLaporan({
    required this.labels,
    required this.datasets,
  });

  factory AsistenLaporan.fromJson(Map<String, dynamic> json) {
    var dataObj = json['data'] ?? {};
    var rawLabels = dataObj['labels'] as List? ?? [];
    var rawDatasets = dataObj['datasets'] as List? ?? [];
    return AsistenLaporan(
      labels: rawLabels.map((e) => e.toString()).toList(),
      datasets: rawDatasets.map((e) => AsistenDataset.fromJson(e)).toList(),
    );
  }
}
