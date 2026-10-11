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
  final int totalSksTahunIni;
  final int sisaSks;
  final int maxSks;
  final List<SpMatkul> matkulTahunBerjalan;
  final List<SpMatkul> matkulTahunLain;

  SpAvailableData({
    required this.isOpen,
    required this.periodeInfo,
    required this.totalSksTahunIni,
    required this.sisaSks,
    required this.maxSks,
    required this.matkulTahunBerjalan,
    required this.matkulTahunLain,
  });

  factory SpAvailableData.fromJson(Map<String, dynamic> json) {
    return SpAvailableData(
      isOpen: json['is_open'] == true,
      periodeInfo: json['periode_info']?.toString() ?? '',
      totalSksTahunIni: int.tryParse(json['total_sks_tahun_ini']?.toString() ?? '0') ?? 0,
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

class SpRekomendasiItem {
  final String kode;
  final String mkl;
  final int sks;
  final String nilaiSebelumnya;
  final String alasan;

  SpRekomendasiItem({
    required this.kode,
    required this.mkl,
    required this.sks,
    required this.nilaiSebelumnya,
    required this.alasan,
  });

  factory SpRekomendasiItem.fromJson(Map<String, dynamic> json) {
    return SpRekomendasiItem(
      kode: json['kode']?.toString() ?? '',
      mkl: json['mkl']?.toString() ?? '',
      sks: int.tryParse(json['sks']?.toString() ?? '0') ?? 0,
      nilaiSebelumnya: json['nilai_sebelumnya']?.toString() ?? '',
      alasan: json['alasan']?.toString() ?? '',
    );
  }
}

class SpRekomendasiData {
  final bool hasRekomendasi;
  final String warningMessage;
  final int totalRekomendasi;
  final int totalSks;
  final List<SpRekomendasiItem> kategoriSangatDianjurkan;
  final List<SpRekomendasiItem> kategoriOpsionalSksBesar;

  SpRekomendasiData({
    required this.hasRekomendasi,
    required this.warningMessage,
    required this.totalRekomendasi,
    required this.totalSks,
    required this.kategoriSangatDianjurkan,
    required this.kategoriOpsionalSksBesar,
  });

  factory SpRekomendasiData.fromJson(Map<String, dynamic> json) {
    return SpRekomendasiData(
      hasRekomendasi: json['has_rekomendasi'] == true,
      warningMessage: json['warning_message']?.toString() ?? '',
      totalRekomendasi: int.tryParse(json['total_rekomendasi']?.toString() ?? '0') ?? 0,
      totalSks: int.tryParse(json['total_sks']?.toString() ?? '0') ?? 0,
      kategoriSangatDianjurkan: (json['kategori_sangat_dianjurkan'] as List?)
              ?.map((e) => SpRekomendasiItem.fromJson(e))
              .toList() ??
          [],
      kategoriOpsionalSksBesar: (json['kategori_opsional_sks_besar'] as List?)
              ?.map((e) => SpRekomendasiItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
