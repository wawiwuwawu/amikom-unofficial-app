class JenisPenelitianOption {
  final String value;
  final String label;

  JenisPenelitianOption({
    required this.value,
    required this.label,
  });

  factory JenisPenelitianOption.fromJson(Map<String, dynamic> json) {
    return JenisPenelitianOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class IzinPenelitianOptions {
  final List<JenisPenelitianOption> jenisPenelitian;
  final List<String> ditujukanPenelitian;

  IzinPenelitianOptions({
    required this.jenisPenelitian,
    required this.ditujukanPenelitian,
  });

  factory IzinPenelitianOptions.fromJson(Map<String, dynamic> json) {
    return IzinPenelitianOptions(
      jenisPenelitian: (json['jenis_penelitian'] as List?)
              ?.map((e) => JenisPenelitianOption.fromJson(e))
              .toList() ??
          [],
      ditujukanPenelitian: (json['ditujukan_penelitian'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class IzinPenelitianItem {
  final String idPengajuan;
  final String tglPengajuan;
  final String thnAjaranSmt;
  final String instansi;
  final String judulPenelitian;
  final String? tglProses;
  final String mulai;
  final String selesai;
  final String status;
  final bool canDelete;

  IzinPenelitianItem({
    required this.idPengajuan,
    required this.tglPengajuan,
    required this.thnAjaranSmt,
    required this.instansi,
    required this.judulPenelitian,
    this.tglProses,
    required this.mulai,
    required this.selesai,
    required this.status,
    required this.canDelete,
  });

  factory IzinPenelitianItem.fromJson(Map<String, dynamic> json) {
    return IzinPenelitianItem(
      idPengajuan: json['id_pengajuan']?.toString() ?? '',
      tglPengajuan: json['tgl_pengajuan']?.toString() ?? '',
      thnAjaranSmt: json['thn_ajaran_smt']?.toString() ?? '',
      instansi: json['instansi']?.toString() ?? '',
      judulPenelitian: json['judul_penelitian']?.toString() ?? '',
      tglProses: json['tgl_proses']?.toString(),
      mulai: json['mulai']?.toString() ?? '',
      selesai: json['selesai']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      canDelete: json['can_delete'] == true,
    );
  }
}

class IzinPenelitianData {
  final IzinPenelitianOptions options;
  final String keteranganBaa;
  final List<IzinPenelitianItem> items;

  IzinPenelitianData({
    required this.options,
    required this.keteranganBaa,
    required this.items,
  });

  factory IzinPenelitianData.fromJson(Map<String, dynamic> json) {
    return IzinPenelitianData(
      options: IzinPenelitianOptions.fromJson(json['options'] ?? {}),
      keteranganBaa: json['keterangan_baa']?.toString() ?? '',
      items: (json['items'] as List?)
              ?.map((e) => IzinPenelitianItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
