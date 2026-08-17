class SkmkOptions {
  final List<String> keperluan;
  final List<String> ortu;

  SkmkOptions({
    required this.keperluan,
    required this.ortu,
  });

  factory SkmkOptions.fromJson(Map<String, dynamic> json) {
    return SkmkOptions(
      keperluan: (json['keperluan'] as List?)?.map((e) => e.toString()).toList() ?? [],
      ortu: (json['ortu'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class SkmkItem {
  final String idPengajuan;
  final String tglPengajuan;
  final String thnAjaranSmt;
  final String keperluan;
  final String? tglProses;
  final String status;
  final String keterangan;
  final bool canDelete;

  SkmkItem({
    required this.idPengajuan,
    required this.tglPengajuan,
    required this.thnAjaranSmt,
    required this.keperluan,
    this.tglProses,
    required this.status,
    required this.keterangan,
    required this.canDelete,
  });

  factory SkmkItem.fromJson(Map<String, dynamic> json) {
    return SkmkItem(
      idPengajuan: json['id_pengajuan']?.toString() ?? '',
      tglPengajuan: json['tgl_pengajuan']?.toString() ?? '',
      thnAjaranSmt: json['thn_ajaran_smt']?.toString() ?? '',
      keperluan: json['keperluan']?.toString() ?? '',
      tglProses: json['tgl_proses']?.toString(),
      status: json['status']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
      canDelete: json['can_delete'] == true,
    );
  }
}

class SkmkData {
  final SkmkOptions options;
  final List<String> persyaratanInfo;
  final String kontakBaa;
  final List<SkmkItem> items;

  SkmkData({
    required this.options,
    required this.persyaratanInfo,
    required this.kontakBaa,
    required this.items,
  });

  factory SkmkData.fromJson(Map<String, dynamic> json) {
    return SkmkData(
      options: SkmkOptions.fromJson(json['options'] ?? {}),
      persyaratanInfo: (json['persyaratan_info'] as List?)?.map((e) => e.toString()).toList() ?? [],
      kontakBaa: json['kontak_baa']?.toString() ?? '',
      items: (json['items'] as List?)?.map((e) => SkmkItem.fromJson(e)).toList() ?? [],
    );
  }
}
