import 'value_label_option.dart';

class PrestasiItem {
  final int id;
  final String npm;
  final String jenisAktivitas;
  final String kejuaraan;
  final String perolehan;
  final String tahun;
  final String file;
  final String fileUrl;
  final int verifikasi;
  final String status;
  final String keterangan;

  PrestasiItem({
    required this.id,
    required this.npm,
    required this.jenisAktivitas,
    required this.kejuaraan,
    required this.perolehan,
    required this.tahun,
    required this.file,
    required this.fileUrl,
    required this.verifikasi,
    required this.status,
    required this.keterangan,
  });

  factory PrestasiItem.fromJson(Map<String, dynamic> json) {
    return PrestasiItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      npm: json['npm']?.toString() ?? '',
      jenisAktivitas: json['jenis_aktivitas']?.toString() ?? '',
      kejuaraan: json['kejuaraan']?.toString() ?? json['judul']?.toString() ?? '',
      perolehan: json['perolehan']?.toString() ?? json['grade']?.toString() ?? '',
      tahun: json['tahun']?.toString() ?? '',
      file: json['file']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      verifikasi: json['verifikasi'] is int ? json['verifikasi'] : int.tryParse(json['verifikasi']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
    );
  }
}

class PrestasiOptionsData {
  final List<ValueLabelOption> jenisPrestasi;
  final List<ValueLabelOption> prestasi;
  final List<ValueLabelOption> prestasiPkm;
  final List<ValueLabelOption> kategoriPkm;
  final List<ValueLabelOption> tingkatan;

  PrestasiOptionsData({
    required this.jenisPrestasi,
    required this.prestasi,
    required this.prestasiPkm,
    required this.kategoriPkm,
    required this.tingkatan,
  });

  factory PrestasiOptionsData.fromJson(Map<String, dynamic> json) {
    List<ValueLabelOption> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => ValueLabelOption.fromJson(e as Map<String, dynamic>)).toList();
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
