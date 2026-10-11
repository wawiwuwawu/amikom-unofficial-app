import 'value_label_option.dart';

class SeminarWorkshopItem {
  final int id;
  final String npm;
  final String jenisAktivitas;
  final String judul;
  final String sebagai;
  final String tahun;
  final String file;
  final String fileUrl;
  final int verifikasi;
  final String status;
  final String keterangan;

  SeminarWorkshopItem({
    required this.id,
    required this.npm,
    required this.jenisAktivitas,
    required this.judul,
    required this.sebagai,
    required this.tahun,
    required this.file,
    required this.fileUrl,
    required this.verifikasi,
    required this.status,
    required this.keterangan,
  });

  factory SeminarWorkshopItem.fromJson(Map<String, dynamic> json) {
    return SeminarWorkshopItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      npm: json['npm']?.toString() ?? '',
      jenisAktivitas: json['jenis_aktivitas']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      sebagai: json['sebagai']?.toString() ?? '',
      tahun: json['tahun']?.toString() ?? '',
      file: json['file']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      verifikasi: json['verifikasi'] is int ? json['verifikasi'] : int.tryParse(json['verifikasi']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
    );
  }
}

class SeminarWorkshopOptionsData {
  final List<ValueLabelOption> jenisKegiatan;
  final List<ValueLabelOption> sebagai;
  final List<ValueLabelOption> tingkatan;

  SeminarWorkshopOptionsData({
    required this.jenisKegiatan,
    required this.sebagai,
    required this.tingkatan,
  });

  factory SeminarWorkshopOptionsData.fromJson(Map<String, dynamic> json) {
    List<ValueLabelOption> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => ValueLabelOption.fromJson(e as Map<String, dynamic>)).toList();
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
