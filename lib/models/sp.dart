class SpMatkul {
  final String kode;
  final String mkl;
  final int sks;
  final String thnAjaran;
  final String semester;
  final String nilai;
  final bool disabled;

  SpMatkul({
    required this.kode,
    required this.mkl,
    required this.sks,
    required this.thnAjaran,
    required this.semester,
    required this.nilai,
    required this.disabled,
  });

  factory SpMatkul.fromJson(Map<String, dynamic> json) {
    return SpMatkul(
      kode: json['kode']?.toString() ?? '',
      mkl: json['mkl']?.toString() ?? '',
      sks: int.tryParse(json['sks']?.toString() ?? '0') ?? 0,
      thnAjaran: json['thn_ajaran']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      nilai: json['nilai']?.toString() ?? '',
      disabled: json['disabled'] == true,
    );
  }
}

class SpAvailableData {
  final bool isOpen;
  final String periodeInfo;
  final String? tanggalMulai;
  final String? tanggalSelesai;
  final int totalSksTahunIni;
  final int jumlahSksLampauDiambil;
  final int sisaSks;
  final int maxSks;
  final List<SpMatkul> matkulTahunBerjalan;
  final List<SpMatkul> matkulTahunLain;

  SpAvailableData({
    required this.isOpen,
    required this.periodeInfo,
    this.tanggalMulai,
    this.tanggalSelesai,
    required this.totalSksTahunIni,
    required this.jumlahSksLampauDiambil,
    required this.sisaSks,
    required this.maxSks,
    required this.matkulTahunBerjalan,
    required this.matkulTahunLain,
  });

  factory SpAvailableData.fromJson(Map<String, dynamic> json) {
    return SpAvailableData(
      isOpen: json['is_open'] == true,
      periodeInfo: json['periode_info']?.toString() ?? '',
      tanggalMulai: json['tanggal_mulai']?.toString(),
      tanggalSelesai: json['tanggal_selesai']?.toString(),
      totalSksTahunIni: int.tryParse(json['total_sks_tahun_ini']?.toString() ?? '0') ?? 0,
      jumlahSksLampauDiambil: int.tryParse(json['jumlah_sks_lampau_diambil']?.toString() ?? '0') ?? 0,
      sisaSks: int.tryParse(json['sisa_sks']?.toString() ?? '0') ?? 0,
      maxSks: int.tryParse(json['max_sks']?.toString() ?? '0') ?? 0,
      matkulTahunBerjalan: (json['matkul_tahun_berjalan'] as List?)
              ?.map((e) => SpMatkul.fromJson(e))
              .toList() ??
          [],
      matkulTahunLain: (json['matkul_tahun_lain'] as List?)
              ?.map((e) => SpMatkul.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SpTakenItem {
  final String idKrs;
  final String kode;
  final String mkl;
  final int sks;
  final bool isActivated;
  final bool canDelete;

  SpTakenItem({
    required this.idKrs,
    required this.kode,
    required this.mkl,
    required this.sks,
    required this.isActivated,
    required this.canDelete,
  });

  factory SpTakenItem.fromJson(Map<String, dynamic> json) {
    return SpTakenItem(
      idKrs: json['id_krs']?.toString() ?? '',
      kode: json['kode']?.toString() ?? '',
      mkl: json['mkl']?.toString() ?? '',
      sks: int.tryParse(json['sks']?.toString() ?? '0') ?? 0,
      isActivated: json['is_activated'] == true,
      canDelete: json['can_delete'] == true,
    );
  }
}

class SpTakenData {
  final int totalSks;
  final List<SpTakenItem> items;

  SpTakenData({
    required this.totalSks,
    required this.items,
  });

  factory SpTakenData.fromJson(Map<String, dynamic> json) {
    return SpTakenData(
      totalSks: int.tryParse(json['total_sks']?.toString() ?? '0') ?? 0,
      items: (json['items'] as List?)
              ?.map((e) => SpTakenItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
