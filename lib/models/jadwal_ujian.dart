class JadwalUjian {
  final String kode;
  final String mkl;
  final String tanggal;
  final String hari;
  final String ruang;
  final String jamMulai;
  final String jamSelesai;
  final int noKursi;
  final int noRef;
  final dynamic nilai;
  final int totalPresensi;
  final int totalPresensiMhs;

  JadwalUjian({
    required this.kode,
    required this.mkl,
    required this.tanggal,
    required this.hari,
    required this.ruang,
    required this.jamMulai,
    required this.jamSelesai,
    required this.noKursi,
    required this.noRef,
    required this.nilai,
    required this.totalPresensi,
    required this.totalPresensiMhs,
  });

  factory JadwalUjian.fromJson(Map<String, dynamic> json) {
    return JadwalUjian(
      kode: json['KODE']?.toString().trim() ?? '',
      mkl: json['MKL']?.toString().trim() ?? '',
      tanggal: json['TANGGAL']?.toString().trim() ?? '',
      hari: json['HARI']?.toString().trim() ?? '',
      ruang: json['RUANG']?.toString().trim() ?? '',
      jamMulai: json['JAM_MULAI']?.toString().trim() ?? '',
      jamSelesai: json['JAM_SELESEI']?.toString().trim() ?? '',
      noKursi: json['NOKURSI'] ?? 0,
      noRef: json['NOREF'] ?? 0,
      nilai: json['nilai'],
      totalPresensi: json['total_presensi'] ?? 0,
      totalPresensiMhs: json['total_presensi_mhs'] ?? 0,
    );
  }
}
