class KrsPeriode {
  final String tanggalMulai;
  final String tanggalSelesai;
  final String teksMentah;

  KrsPeriode({
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.teksMentah,
  });

  factory KrsPeriode.fromJson(Map<String, dynamic> json) {
    return KrsPeriode(
      tanggalMulai: json['tanggal_mulai'] ?? '',
      tanggalSelesai: json['tanggal_selesai'] ?? '',
      teksMentah: json['teks_mentah'] ?? '',
    );
  }
}

class KrsTagihan {
  final String downloadUrl;
  final String tahunAkademik;
  final String semester;

  KrsTagihan({
    required this.downloadUrl,
    required this.tahunAkademik,
    required this.semester,
  });

  factory KrsTagihan.fromJson(Map<String, dynamic> json) {
    return KrsTagihan(
      downloadUrl: json['download_url'] ?? '',
      tahunAkademik: json['tahun_akademik'] ?? '',
      semester: json['semester'] ?? '',
    );
  }
}

class KrsInfo {
  final KrsPeriode? periodePengajuan;
  final KrsPeriode? periodePengisian;
  final KrsTagihan? tagihan;

  KrsInfo({
    this.periodePengajuan,
    this.periodePengisian,
    this.tagihan,
  });

  factory KrsInfo.fromJson(Map<String, dynamic> json) {
    return KrsInfo(
      periodePengajuan: json['periode_pengajuan'] != null ? KrsPeriode.fromJson(json['periode_pengajuan']) : null,
      periodePengisian: json['periode_pengisian'] != null ? KrsPeriode.fromJson(json['periode_pengisian']) : null,
      tagihan: json['tagihan'] != null ? KrsTagihan.fromJson(json['tagihan']) : null,
    );
  }
}

class MatkulDitawarkan {
  final int semester;
  final String kode;
  final String nama;
  final int sks;
  final String status;
  final bool isUlang;
  final String? nilaiSebelumnya;

  MatkulDitawarkan({
    required this.semester,
    required this.kode,
    required this.nama,
    required this.sks,
    required this.status,
    required this.isUlang,
    this.nilaiSebelumnya,
  });

  factory MatkulDitawarkan.fromJson(Map<String, dynamic> json) {
    return MatkulDitawarkan(
      semester: json['semester'] ?? 0,
      kode: json['kode'] ?? '',
      nama: json['nama'] ?? '',
      sks: json['sks'] ?? 0,
      status: json['status'] ?? '',
      isUlang: json['isUlang'] ?? false,
      nilaiSebelumnya: json['nilaiSebelumnya'],
    );
  }
}

class MatkulDitawarkanResponse {
  final List<MatkulDitawarkan> data;
  final int maxSks;
  final int sksSaatIni;

  MatkulDitawarkanResponse({
    required this.data,
    required this.maxSks,
    required this.sksSaatIni,
  });

  factory MatkulDitawarkanResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    return MatkulDitawarkanResponse(
      data: list.map((e) => MatkulDitawarkan.fromJson(e)).toList(),
      maxSks: json['max_sks'] ?? 0,
      sksSaatIni: json['sks_saat_ini'] ?? 0,
    );
  }
}

class KrsPengajuan {
  final int idKrs;
  final int sks;
  final String kode;
  final int total;
  final String mkl;
  final int aktivasi;
  final int ambilKe;

  KrsPengajuan({
    required this.idKrs,
    required this.sks,
    required this.kode,
    required this.total,
    required this.mkl,
    required this.aktivasi,
    required this.ambilKe,
  });

  factory KrsPengajuan.fromJson(Map<String, dynamic> json) {
    return KrsPengajuan(
      idKrs: json['ID_KRS'] ?? 0,
      sks: json['SKS'] ?? 0,
      kode: json['KODE'] ?? '',
      total: json['TOTAL'] ?? 0,
      mkl: json['MKL'] ?? '',
      aktivasi: json['AKTIVASI'] ?? 0,
      ambilKe: json['AMBILKE'] ?? 0,
    );
  }
}

class KrsPengajuanResponse {
  final List<KrsPengajuan> data;
  final int totalSks;

  KrsPengajuanResponse({
    required this.data,
    required this.totalSks,
  });

  factory KrsPengajuanResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    return KrsPengajuanResponse(
      data: list.map((e) => KrsPengajuan.fromJson(e)).toList(),
      totalSks: json['total_sks'] ?? 0,
    );
  }
}

class KrsPengisian {
  final String no;
  final String kodeMk;
  final String namaMataKuliah;
  final String dosenKelas;
  final String sks;
  final String bU;
  final String ket;
  final String jenis;
  final String hari;
  final String ruang;
  final String jam;
  final String? aksi;

  KrsPengisian({
    required this.no,
    required this.kodeMk,
    required this.namaMataKuliah,
    required this.dosenKelas,
    required this.sks,
    required this.bU,
    required this.ket,
    required this.jenis,
    required this.hari,
    required this.ruang,
    required this.jam,
    this.aksi,
  });

  factory KrsPengisian.fromJson(Map<String, dynamic> json) {
    return KrsPengisian(
      no: json['no']?.toString() ?? '',
      kodeMk: json['kode_mk'] ?? '',
      namaMataKuliah: json['nama_mata_kuliah'] ?? '',
      dosenKelas: json['dosen_kelas'] ?? '',
      sks: json['sks']?.toString() ?? '',
      bU: json['b_u'] ?? '',
      ket: json['ket'] ?? '',
      jenis: json['jenis'] ?? '',
      hari: json['hari'] ?? '',
      ruang: json['ruang'] ?? '',
      jam: json['jam'] ?? '',
      aksi: json['aksi'],
    );
  }
}

class KrsPengisianResponse {
  final List<KrsPengisian> data;

  KrsPengisianResponse({required this.data});

  factory KrsPengisianResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    return KrsPengisianResponse(
      data: list.map((e) => KrsPengisian.fromJson(e)).toList(),
    );
  }
}

class JadwalKuliahResponse {
  final List<KrsPengisian> data;
  final int totalSks;

  JadwalKuliahResponse({
    required this.data,
    required this.totalSks,
  });

  factory JadwalKuliahResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    return JadwalKuliahResponse(
      data: list.map((e) => KrsPengisian.fromJson(e)).toList(),
      totalSks: json['total_sks'] ?? 0,
    );
  }
}
