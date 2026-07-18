class OrganisasiItem {
  final int id;
  final String npm;
  final String jenisAktivitas;
  final String namaOrganisasi;
  final String namaOrganisasiEnglish;
  final String jabatan;
  final String jabatanEnglish;
  final int tahun;
  final String file;
  final String fileUrl;
  final int verifikasi;
  final String status;
  final String keterangan;
  final String createdAt;
  final String updatedAt;

  OrganisasiItem({
    required this.id,
    required this.npm,
    required this.jenisAktivitas,
    required this.namaOrganisasi,
    required this.namaOrganisasiEnglish,
    required this.jabatan,
    required this.jabatanEnglish,
    required this.tahun,
    required this.file,
    required this.fileUrl,
    required this.verifikasi,
    required this.status,
    required this.keterangan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganisasiItem.fromJson(Map<String, dynamic> json) {
    return OrganisasiItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      npm: json['npm']?.toString() ?? '',
      jenisAktivitas: json['jenis_aktivitas']?.toString() ?? '',
      namaOrganisasi: json['nama_organisasi']?.toString() ?? '',
      namaOrganisasiEnglish: json['nama_organisasi_english']?.toString() ?? '',
      jabatan: json['jabatan']?.toString() ?? '',
      jabatanEnglish: json['jabatan_english']?.toString() ?? '',
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

class DropdownOption {
  final String value;
  final String label;

  DropdownOption({
    required this.value,
    required this.label,
  });

  factory DropdownOption.fromJson(Map<String, dynamic> json) {
    return DropdownOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class OrganisasiOptionResponse {
  final List<DropdownOption> organisasi;
  final List<DropdownOption> jabatan;

  OrganisasiOptionResponse({
    required this.organisasi,
    required this.jabatan,
  });

  factory OrganisasiOptionResponse.fromJson(Map<String, dynamic> json) {
    final orgList = json['organisasi'] as List?;
    final jabList = json['jabatan'] as List?;
    return OrganisasiOptionResponse(
      organisasi: orgList?.map((e) => DropdownOption.fromJson(e)).toList() ?? [],
      jabatan: jabList?.map((e) => DropdownOption.fromJson(e)).toList() ?? [],
    );
  }
}
