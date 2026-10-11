import 'value_label_option.dart';

class OrganisasiItem {
  final int id;
  final String npm;
  final String jenisAktivitas;
  final String namaOrganisasi;
  final String jabatan;
  final int tahun;
  final String file;
  final String fileUrl;
  final int verifikasi;
  final String status;
  final String keterangan;

  OrganisasiItem({
    required this.id,
    required this.npm,
    required this.jenisAktivitas,
    required this.namaOrganisasi,
    required this.jabatan,
    required this.tahun,
    required this.file,
    required this.fileUrl,
    required this.verifikasi,
    required this.status,
    required this.keterangan,
  });

  factory OrganisasiItem.fromJson(Map<String, dynamic> json) {
    return OrganisasiItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      npm: json['npm']?.toString() ?? '',
      jenisAktivitas: json['jenis_aktivitas']?.toString() ?? '',
      namaOrganisasi: json['nama_organisasi']?.toString() ?? '',
      jabatan: json['jabatan']?.toString() ?? '',
      tahun: json['tahun'] is int ? json['tahun'] : int.tryParse(json['tahun']?.toString() ?? '0') ?? 0,
      file: json['file']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      verifikasi: json['verifikasi'] is int ? json['verifikasi'] : int.tryParse(json['verifikasi']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
    );
  }
}

class OrganisasiOptionResponse {
  final List<ValueLabelOption> organisasi;
  final List<ValueLabelOption> jabatan;

  OrganisasiOptionResponse({
    required this.organisasi,
    required this.jabatan,
  });

  factory OrganisasiOptionResponse.fromJson(Map<String, dynamic> json) {
    final orgList = json['organisasi'] as List?;
    final jabList = json['jabatan'] as List?;
    return OrganisasiOptionResponse(
      organisasi: orgList?.map((e) => ValueLabelOption.fromJson(e)).toList() ?? [],
      jabatan: jabList?.map((e) => ValueLabelOption.fromJson(e)).toList() ?? [],
    );
  }
}
