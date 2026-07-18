class SertifikasiItem {
  final int id;
  final String npm;
  final String jenisAktivitas;
  final String judul;
  final String judulEnglish;
  final String grade;
  final String gradeEnglish;
  final int tahun;
  final String file;
  final String fileUrl;
  final int verifikasi;
  final String status;
  final String keterangan;
  final String createdAt;
  final String updatedAt;

  SertifikasiItem({
    required this.id,
    required this.npm,
    required this.jenisAktivitas,
    required this.judul,
    required this.judulEnglish,
    required this.grade,
    required this.gradeEnglish,
    required this.tahun,
    required this.file,
    required this.fileUrl,
    required this.verifikasi,
    required this.status,
    required this.keterangan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SertifikasiItem.fromJson(Map<String, dynamic> json) {
    return SertifikasiItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      npm: json['npm']?.toString() ?? '',
      jenisAktivitas: json['jenis_aktivitas']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      judulEnglish: json['judul_english']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      gradeEnglish: json['grade_english']?.toString() ?? '',
      tahun: json['tahun'] is int ? json['tahun'] : int.tryParse(json['tahun']?.toString() ?? '0') ?? 0,
      file: json['file']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      verifikasi: json['verifikasi'] is int ? json['verifikasi'] : int.tryParse(json['verifikasi']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class SertifikasiOption {
  final String value;
  final String label;

  SertifikasiOption({
    required this.value,
    required this.label,
  });

  factory SertifikasiOption.fromJson(Map<String, dynamic> json) {
    return SertifikasiOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}
