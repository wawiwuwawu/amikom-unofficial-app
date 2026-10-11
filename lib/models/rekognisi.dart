import 'value_label_option.dart';

class RekognisiItem {
  final int id;
  final String npm;
  final String jenisAktivitas;
  final String judul;
  final String tingkat;
  final String link;
  final String kontribusi;
  final int tahun;
  final String file;
  final String fileUrl;
  final int verifikasi;
  final String status;
  final String keterangan;

  RekognisiItem({
    required this.id,
    required this.npm,
    required this.jenisAktivitas,
    required this.judul,
    required this.tingkat,
    required this.link,
    required this.kontribusi,
    required this.tahun,
    required this.file,
    required this.fileUrl,
    required this.verifikasi,
    required this.status,
    required this.keterangan,
  });

  factory RekognisiItem.fromJson(Map<String, dynamic> json) {
    return RekognisiItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      npm: json['npm']?.toString() ?? '',
      jenisAktivitas: json['jenis_aktivitas']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      tingkat: json['tingkat']?.toString() ?? '',
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
    );
  }
}

class RekognisiOptionResponse {
  final List<ValueLabelOption> jenisRekognisi;
  final List<ValueLabelOption> tingkat;
  final List<ValueLabelOption> kontribusi;

  RekognisiOptionResponse({
    required this.jenisRekognisi,
    required this.tingkat,
    required this.kontribusi,
  });

  factory RekognisiOptionResponse.fromJson(Map<String, dynamic> json) {
    List<ValueLabelOption> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) {
          if (e is Map<String, dynamic>) {
            return ValueLabelOption.fromJson(e);
          } else if (e is Map) {
            return ValueLabelOption.fromJson(Map<String, dynamic>.from(e));
          }
          return ValueLabelOption(value: '', label: '');
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
