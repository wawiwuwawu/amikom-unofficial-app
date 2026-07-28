class SeminarWorkshopItem {
  final int id;
  final String npm;
  final String jenisAktivitas;
  final String judul;
  final String judulEnglish;
  final String sebagai;
  final String sebagaiEnglish;
  final String tahun;
  final String file;
  final String fileUrl;
  final int verifikasi;
  final String status;
  final String keterangan;
  final String createdAt;
  final String updatedAt;

  SeminarWorkshopItem({
    required this.id,
    required this.npm,
    required this.jenisAktivitas,
    required this.judul,
    required this.judulEnglish,
    required this.sebagai,
    required this.sebagaiEnglish,
    required this.tahun,
    required this.file,
    required this.fileUrl,
    required this.verifikasi,
    required this.status,
    required this.keterangan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SeminarWorkshopItem.fromJson(Map<String, dynamic> json) {
    return SeminarWorkshopItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      npm: json['npm']?.toString() ?? '',
      jenisAktivitas: json['jenis_aktivitas']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      judulEnglish: json['judul_english']?.toString() ?? '',
      sebagai: json['sebagai']?.toString() ?? '',
      sebagaiEnglish: json['sebagai_english']?.toString() ?? '',
      tahun: json['tahun']?.toString() ?? '',
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

class SeminarWorkshopOption {
  final String value;
  final String label;

  SeminarWorkshopOption({
    required this.value,
    required this.label,
  });

  factory SeminarWorkshopOption.fromJson(Map<String, dynamic> json) {
    return SeminarWorkshopOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class SeminarWorkshopOptionsData {
  final List<SeminarWorkshopOption> jenisKegiatan;
  final List<SeminarWorkshopOption> sebagai;
  final List<SeminarWorkshopOption> tingkatan;

  SeminarWorkshopOptionsData({
    required this.jenisKegiatan,
    required this.sebagai,
    required this.tingkatan,
  });

  factory SeminarWorkshopOptionsData.fromJson(Map<String, dynamic> json) {
    List<SeminarWorkshopOption> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => SeminarWorkshopOption.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return SeminarWorkshopOptionsData(
      jenisKegiatan: parseList(json['jenis_kegiatan']),
      sebagai: parseList(json['sebagai']),
      tingkatan: parseList(json['tingkatan']),
    );
  }
}
