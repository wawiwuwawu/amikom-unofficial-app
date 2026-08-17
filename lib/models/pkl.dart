class PklJenisOption {
  final String value;
  final String label;

  PklJenisOption({
    required this.value,
    required this.label,
  });

  factory PklJenisOption.fromJson(Map<String, dynamic> json) {
    return PklJenisOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class PklOptions {
  final List<PklJenisOption> jenis;

  PklOptions({
    required this.jenis,
  });

  factory PklOptions.fromJson(Map<String, dynamic> json) {
    return PklOptions(
      jenis: (json['jenis'] as List?)
              ?.map((e) => PklJenisOption.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PklItem {
  final String idPengajuan;
  final String judul;
  final String jenis;
  final String tglPengajuan;
  final String status;
  final String? tglUjian;
  final String? ruang;
  final String? jam;
  final bool isActivated;
  final bool canDelete;
  final bool canDownload;

  PklItem({
    required this.idPengajuan,
    required this.judul,
    required this.jenis,
    required this.tglPengajuan,
    required this.status,
    this.tglUjian,
    this.ruang,
    this.jam,
    required this.isActivated,
    required this.canDelete,
    required this.canDownload,
  });

  factory PklItem.fromJson(Map<String, dynamic> json) {
    return PklItem(
      idPengajuan: json['id_pengajuan']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      jenis: json['jenis']?.toString() ?? '',
      tglPengajuan: json['tgl_pengajuan']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      tglUjian: json['tgl_ujian']?.toString(),
      ruang: json['ruang']?.toString(),
      jam: json['jam']?.toString(),
      isActivated: json['is_activated'] == true,
      canDelete: json['can_delete'] == true,
      canDownload: json['can_download'] == true,
    );
  }
}

class PklData {
  final bool canApply;
  final String? warningMessage;
  final List<String> informasi;
  final PklOptions options;
  final List<PklItem> items;

  PklData({
    required this.canApply,
    this.warningMessage,
    required this.informasi,
    required this.options,
    required this.items,
  });

  factory PklData.fromJson(Map<String, dynamic> json) {
    return PklData(
      canApply: json['can_apply'] == true,
      warningMessage: json['warning_message']?.toString(),
      informasi: (json['informasi'] as List?)?.map((e) => e.toString()).toList() ?? [],
      options: PklOptions.fromJson(json['options'] ?? {}),
      items: (json['items'] as List?)?.map((e) => PklItem.fromJson(e)).toList() ?? [],
    );
  }
}
