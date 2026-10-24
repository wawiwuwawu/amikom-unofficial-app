class JadwalUjian {
  final String kode;
  final String mkl;
  final String tanggal;
  final String hari;
  final String ruang;
  final String jamMulai;
  final String jamSelesai;
  final int noKursi;
  final dynamic nilai;

  JadwalUjian({
    required this.kode,
    required this.mkl,
    required this.tanggal,
    required this.hari,
    required this.ruang,
    required this.jamMulai,
    required this.jamSelesai,
    required this.noKursi,
    required this.nilai,
  });

  factory JadwalUjian.fromJson(Map<String, dynamic> json) {
    return JadwalUjian(
      kode: json['KODE']?.toString().trim() ?? '',
      mkl: json['MKL']?.toString().trim() ?? '',
      // Portal memakai dua key untuk tanggal yang sama: `TANGGAL` pada UTS dan
      // `TGL_UJIAN` pada UAS (akan diseragamkan BE — lihat pesan-be.md).
      // Alias key sederhana, bukan fallback berlapis.
      tanggal:
          (json['TANGGAL'] ?? json['TGL_UJIAN'])?.toString().trim() ?? '',
      hari: json['HARI']?.toString().trim() ?? '',
      ruang: json['RUANG']?.toString().trim() ?? '',
      jamMulai: json['JAM_MULAI']?.toString().trim() ?? '',
      jamSelesai: json['JAM_SELESEI']?.toString().trim() ?? '',
      noKursi: json['NOKURSI'] ?? 0,
      nilai: json['nilai'],
    );
  }
}
