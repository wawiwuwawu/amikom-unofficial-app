class RekognisiItem {
  final int id;
  final String npm;
  final String jenisAktivitas;
  final String judul;
  final String judulEnglish;
  final String tingkat;
  final String tingkatEnglish;
  final String link;
  final String kontribusi;
  final int tahun;
  final String file;
  final String fileUrl;
  final int verifikasi;
  final String status;
  final String keterangan;
  final String createdAt;
  final String updatedAt;

  RekognisiItem({
    required this.id,
    required this.npm,
    required this.jenisAktivitas,
    required this.judul,
    required this.judulEnglish,
    required this.tingkat,
    required this.tingkatEnglish,
    required this.link,
    required this.kontribusi,
    required this.tahun,
    required this.file,
    required this.fileUrl,
    required this.verifikasi,
    required this.status,
    required this.keterangan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RekognisiItem.fromJson(Map<String, dynamic> json) {
    return RekognisiItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      npm: json['npm']?.toString() ?? '',
      jenisAktivitas: json['jenis_aktivitas']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      judulEnglish: json['judul_english']?.toString() ?? '',
      tingkat: json['tingkat']?.toString() ?? '',
      tingkatEnglish: json['tingkat_english']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      kontribusi: json['kontribusi']?.toString() ?? '',
      tahun: json['tahun'] is int
          ? json['tahun'] as int
          : int.tryParse(json['tahun']?.toString() ?? '0') ?? 0,
      file: json['file']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      verifikasi: json['verifikasi'] is int
          ? json['verifikasi'] as int
          : int.tryParse(json['verifikasi']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class RekognisiOptionItem {
  final String value;
  final String label;

  RekognisiOptionItem({
    required this.value,
    required this.label,
  });

  factory RekognisiOptionItem.fromJson(Map<String, dynamic> json) {
    return RekognisiOptionItem(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class RekognisiOptionResponse {
  final List<RekognisiOptionItem> jenisRekognisi;
  final List<RekognisiOptionItem> tingkat;
  final List<RekognisiOptionItem> kontribusi;

  RekognisiOptionResponse({
    required this.jenisRekognisi,
    required this.tingkat,
    required this.kontribusi,
  });

  factory RekognisiOptionResponse.fromJson(Map<String, dynamic> json) {
    List<RekognisiOptionItem> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) {
          if (e is Map<String, dynamic>) {
            return RekognisiOptionItem.fromJson(e);
          } else if (e is Map) {
            return RekognisiOptionItem.fromJson(Map<String, dynamic>.from(e));
          }
          return RekognisiOptionItem(value: '', label: '');
        }).toList();
      }
      return [];
    }

    return RekognisiOptionResponse(
      jenisRekognisi: parseList(json['jenis_rekognisi']),
      tingkat: parseList(json['tingkat']),
      kontribusi: parseList(json['kontribusi']),
    );
  }
}
