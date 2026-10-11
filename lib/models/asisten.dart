class AsistenMahasiswa {
  final String npm;
  final String nama;
  final String namaDept;

  AsistenMahasiswa({
    required this.npm,
    required this.nama,
    required this.namaDept,
  });

  factory AsistenMahasiswa.fromJson(Map<String, dynamic> json) {
    return AsistenMahasiswa(
      npm: json['npm'] ?? '',
      nama: json['NAMA'] ?? '',
      namaDept: json['nama_dept'] ?? '',
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

class AsistenInfo {
  final AsistenMahasiswa mahasiswa;
  final AsistenStats stats;
  final bool bisaAjukanBebasKP;

  AsistenInfo({
    required this.mahasiswa,
    required this.stats,
    required this.bisaAjukanBebasKP,
  });

  factory AsistenInfo.fromJson(Map<String, dynamic> json) {
    final map = (json['mahasiswa'] != null || json['stats'] != null)
        ? json
        : (json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json);
    return AsistenInfo(
      mahasiswa: AsistenMahasiswa.fromJson(map['mahasiswa'] ?? {}),
      stats: AsistenStats.fromJson(map['stats'] ?? {}),
      bisaAjukanBebasKP: map['bisaAjukanBebasKP'] ?? false,
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

  AsistenJadwalResponse({required this.data});

  factory AsistenJadwalResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    return AsistenJadwalResponse(
      data: list.map((e) => AsistenJadwal.fromJson(e)).toList(),
    );
  }
}

class AsistenDataset {
  final String type;
  final String label;
  final List<double> data;

  AsistenDataset({
    required this.type,
    required this.label,
    required this.data,
  });

  factory AsistenDataset.fromJson(Map<String, dynamic> json) {
    var rawData = json['data'] as List? ?? [];
    return AsistenDataset(
      type: json['type'] ?? '',
      label: json['label'] ?? '',
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
    final dataObj = (json['labels'] != null || json['datasets'] != null)
        ? json
        : (json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json);
    var rawLabels = dataObj['labels'] as List? ?? [];
    var rawDatasets = dataObj['datasets'] as List? ?? [];
    return AsistenLaporan(
      labels: rawLabels.map((e) => e.toString()).toList(),
      datasets: rawDatasets.map((e) => AsistenDataset.fromJson(e)).toList(),
    );
  }
}
