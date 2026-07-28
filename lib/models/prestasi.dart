class PrestasiItem {
  final int id;
  final String npm;
  final String jenisAktivitas;
  final String kejuaraan;
  final String kejuaraanEnglish;
  final String perolehan;
  final String perolehanEnglish;
  final String tahun;
  final String file;
  final String fileUrl;
  final int verifikasi;
  final String status;
  final String keterangan;
  final String createdAt;
  final String updatedAt;

  PrestasiItem({
    required this.id,
    required this.npm,
    required this.jenisAktivitas,
    required this.kejuaraan,
    required this.kejuaraanEnglish,
    required this.perolehan,
    required this.perolehanEnglish,
    required this.tahun,
    required this.file,
    required this.fileUrl,
    required this.verifikasi,
    required this.status,
    required this.keterangan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrestasiItem.fromJson(Map<String, dynamic> json) {
    return PrestasiItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      npm: json['npm']?.toString() ?? '',
      jenisAktivitas: json['jenis_aktivitas']?.toString() ?? '',
      kejuaraan: json['kejuaraan']?.toString() ?? json['judul']?.toString() ?? '',
      kejuaraanEnglish: json['kejuaraan_english']?.toString() ?? json['judul_english']?.toString() ?? '',
      perolehan: json['perolehan']?.toString() ?? json['grade']?.toString() ?? '',
      perolehanEnglish: json['perolehan_english']?.toString() ?? json['grade_english']?.toString() ?? '',
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

class PrestasiOption {
  final String value;
  final String label;

  PrestasiOption({
    required this.value,
    required this.label,
  });

  factory PrestasiOption.fromJson(Map<String, dynamic> json) {
    return PrestasiOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class PrestasiOptionsData {
  final List<PrestasiOption> jenisPrestasi;
  final List<PrestasiOption> prestasi;
  final List<PrestasiOption> prestasiPkm;
  final List<PrestasiOption> kategoriPkm;
  final List<PrestasiOption> tingkatan;

  PrestasiOptionsData({
    required this.jenisPrestasi,
    required this.prestasi,
    required this.prestasiPkm,
    required this.kategoriPkm,
    required this.tingkatan,
  });

  factory PrestasiOptionsData.fromJson(Map<String, dynamic> json) {
    List<PrestasiOption> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => PrestasiOption.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return PrestasiOptionsData(
      jenisPrestasi: parseList(json['jenis_prestasi']),
      prestasi: parseList(json['prestasi']),
      prestasiPkm: parseList(json['prestasi_pkm']),
      kategoriPkm: parseList(json['kategori_pkm']),
      tingkatan: parseList(json['tingkatan']),
    );
  }
}
