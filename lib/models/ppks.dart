class PpksStatusPelaporOption {
  final String value;
  final String label;

  PpksStatusPelaporOption({
    required this.value,
    required this.label,
  });

  factory PpksStatusPelaporOption.fromJson(Map<String, dynamic> json) {
    return PpksStatusPelaporOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class PpksOptions {
  final List<PpksStatusPelaporOption> statusPelapor;
  final List<String> jenisKelamin;
  final List<String> statusPihak;
  final List<String> disabilitas;
  final List<String> alasanPengaduan;
  final List<String> kebutuhanKorban;

  PpksOptions({
    required this.statusPelapor,
    required this.jenisKelamin,
    required this.statusPihak,
    required this.disabilitas,
    required this.alasanPengaduan,
    required this.kebutuhanKorban,
  });

  factory PpksOptions.fromJson(Map<String, dynamic> json) {
    return PpksOptions(
      statusPelapor: (json['status_pelapor'] as List?)
              ?.map((e) => PpksStatusPelaporOption.fromJson(e))
              .toList() ??
          [],
      jenisKelamin: (json['jenis_kelamin'] as List?)?.map((e) => e.toString()).toList() ?? [],
      statusPihak: (json['status_pihak'] as List?)?.map((e) => e.toString()).toList() ?? [],
      disabilitas: (json['disabilitas'] as List?)?.map((e) => e.toString()).toList() ?? [],
      alasanPengaduan: (json['alasan_pengaduan'] as List?)?.map((e) => e.toString()).toList() ?? [],
      kebutuhanKorban: (json['kebutuhan_korban'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class PpksData {
  final String infoPrivacy;
  final PpksOptions options;

  PpksData({
    required this.infoPrivacy,
    required this.options,
  });

  factory PpksData.fromJson(Map<String, dynamic> json) {
    return PpksData(
      infoPrivacy: json['info_privacy']?.toString() ?? '',
      options: PpksOptions.fromJson(json['options'] ?? {}),
    );
  }
}
