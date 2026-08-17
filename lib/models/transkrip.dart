class TranskripItem {
  final String kode;
  final String mkl;
  final int sks;
  final double bobot;
  final String nilai;
  final double totalBobot;

  TranskripItem({
    required this.kode,
    required this.mkl,
    required this.sks,
    required this.bobot,
    required this.nilai,
    required this.totalBobot,
  });

  factory TranskripItem.fromJson(Map<String, dynamic> json) => TranskripItem(
        kode: json['KODE'] ?? '',
        mkl: json['MKL'] ?? '',
        sks: (json['SKS'] ?? 0).toInt(),
        bobot: double.tryParse(json['BOBOT']?.toString() ?? '0') ?? 0,
        nilai: json['NILAI'] ?? '',
        totalBobot: double.tryParse(json['TOTAL_BOBOT']?.toString() ?? '0') ?? 0,
      );
}

class SyaratDetail {
  final bool isFulfilled;
  final String currentVal;
  final String target;
  final String description;

  SyaratDetail({
    required this.isFulfilled,
    required this.currentVal,
    required this.target,
    required this.description,
  });

  factory SyaratDetail.fromJson(Map<String, dynamic> json) {
    return SyaratDetail(
      isFulfilled: json['is_fulfilled'] == true,
      currentVal: json['current_val']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class ViolatingMatkul {
  final String kode;
  final String mkl;
  final int sks;
  final String nilai;

  ViolatingMatkul({
    required this.kode,
    required this.mkl,
    required this.sks,
    required this.nilai,
  });

  factory ViolatingMatkul.fromJson(Map<String, dynamic> json) {
    return ViolatingMatkul(
      kode: json['kode']?.toString() ?? '',
      mkl: json['mkl']?.toString() ?? '',
      sks: int.tryParse(json['sks']?.toString() ?? '0') ?? 0,
      nilai: json['nilai']?.toString() ?? '',
    );
  }
}

class SyaratNilaiMinimumDetail {
  final bool isFulfilled;
  final int violatingMatkulCount;
  final String target;
  final String description;
  final List<ViolatingMatkul> violatingMatkul;

  SyaratNilaiMinimumDetail({
    required this.isFulfilled,
    required this.violatingMatkulCount,
    required this.target,
    required this.description,
    required this.violatingMatkul,
  });

  factory SyaratNilaiMinimumDetail.fromJson(Map<String, dynamic> json) {
    return SyaratNilaiMinimumDetail(
      isFulfilled: json['is_fulfilled'] == true,
      violatingMatkulCount: int.tryParse(json['violating_matkul_count']?.toString() ?? '0') ?? 0,
      target: json['target']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      violatingMatkul: (json['violating_matkul'] as List?)
              ?.map((e) => ViolatingMatkul.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AnalisisSyarat {
  final SyaratDetail syaratIpk;
  final SyaratDetail syaratMasaStudi;
  final SyaratDetail syaratStatusMasuk;
  final SyaratNilaiMinimumDetail syaratNilaiMinimum;

  AnalisisSyarat({
    required this.syaratIpk,
    required this.syaratMasaStudi,
    required this.syaratStatusMasuk,
    required this.syaratNilaiMinimum,
  });

  factory AnalisisSyarat.fromJson(Map<String, dynamic> json) {
    return AnalisisSyarat(
      syaratIpk: SyaratDetail.fromJson(json['syarat_ipk'] ?? {}),
      syaratMasaStudi: SyaratDetail.fromJson(json['syarat_masa_studi'] ?? {}),
      syaratStatusMasuk: SyaratDetail.fromJson(json['syarat_status_masuk'] ?? {}),
      syaratNilaiMinimum: SyaratNilaiMinimumDetail.fromJson(json['syarat_nilai_minimum'] ?? {}),
    );
  }
}

class CumlaudeData {
  final bool isCumlaudeEligible;
  final String predikatSaatIni;
  final double ipkTerakhir;
  final int totalSksLulus;
  final int semesterSaatIni;
  final AnalisisSyarat analisisSyarat;
  final List<String> rekomendasiTindakan;

  CumlaudeData({
    required this.isCumlaudeEligible,
    required this.predikatSaatIni,
    required this.ipkTerakhir,
    required this.totalSksLulus,
    required this.semesterSaatIni,
    required this.analisisSyarat,
    required this.rekomendasiTindakan,
  });

  factory CumlaudeData.fromJson(Map<String, dynamic> json) {
    return CumlaudeData(
      isCumlaudeEligible: json['is_cumlaude_eligible'] == true,
      predikatSaatIni: json['predikat_saat_ini']?.toString() ?? 'Memuaskan',
      ipkTerakhir: double.tryParse(json['ipk_terakhir']?.toString() ?? '0') ?? 0.0,
      totalSksLulus: int.tryParse(json['total_sks_lulus']?.toString() ?? '0') ?? 0,
      semesterSaatIni: int.tryParse(json['semester_saat_ini']?.toString() ?? '0') ?? 0,
      analisisSyarat: AnalisisSyarat.fromJson(json['analisis_syarat'] ?? {}),
      rekomendasiTindakan: (json['rekomendasi_tindakan'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class KelayakanWisuda {
  final bool ipkLulusEligible;
  final double ipkTerakhir;
  final double minIpkLulus;
  final bool bebasNilaiDEEligible;
  final int dEMatkulCount;
  final List<ViolatingMatkul> dEMatkulItems;
  final String warningWisuda;

  KelayakanWisuda({
    required this.ipkLulusEligible,
    required this.ipkTerakhir,
    required this.minIpkLulus,
    required this.bebasNilaiDEEligible,
    required this.dEMatkulCount,
    required this.dEMatkulItems,
    required this.warningWisuda,
  });

  factory KelayakanWisuda.fromJson(Map<String, dynamic> json) {
    return KelayakanWisuda(
      ipkLulusEligible: json['ipk_lulus_eligible'] == true,
      ipkTerakhir: double.tryParse(json['ipk_terakhir']?.toString() ?? '0') ?? 0.0,
      minIpkLulus: double.tryParse(json['min_ipk_lulus']?.toString() ?? '2.5') ?? 2.5,
      bebasNilaiDEEligible: json['bebas_nilai_d_e_eligible'] == true,
      dEMatkulCount: int.tryParse(json['d_e_matkul_count']?.toString() ?? '0') ?? 0,
      dEMatkulItems: (json['d_e_matkul_items'] as List?)
              ?.map((e) => ViolatingMatkul.fromJson(e))
              .toList() ??
          [],
      warningWisuda: json['warning_wisuda']?.toString() ?? '',
    );
  }
}

class SkripsiRegulerInfo {
  final bool pklEligible;
  final bool skripsiEligible;
  final int sisaSksMenujuSkripsi;

  SkripsiRegulerInfo({
    required this.pklEligible,
    required this.skripsiEligible,
    required this.sisaSksMenujuSkripsi,
  });

  factory SkripsiRegulerInfo.fromJson(Map<String, dynamic> json) {
    return SkripsiRegulerInfo(
      pklEligible: json['pkl_eligible'] == true,
      skripsiEligible: json['skripsi_eligible'] == true,
      sisaSksMenujuSkripsi: int.tryParse(json['sisa_sks_menuju_skripsi']?.toString() ?? '0') ?? 0,
    );
  }
}

class TechnopreneurItInfo {
  final bool eligibleSksIpk;
  final int sisaSksMenuju140;
  final List<String> syaratTambahan;

  TechnopreneurItInfo({
    required this.eligibleSksIpk,
    required this.sisaSksMenuju140,
    required this.syaratTambahan,
  });

  factory TechnopreneurItInfo.fromJson(Map<String, dynamic> json) {
    return TechnopreneurItInfo(
      eligibleSksIpk: json['eligible_sks_ipk'] == true,
      sisaSksMenuju140: int.tryParse(json['sisa_sks_menuju_140']?.toString() ?? '0') ?? 0,
      syaratTambahan: (json['syarat_tambahan'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class JalurKelulusan {
  final SkripsiRegulerInfo skripsiReguler;
  final TechnopreneurItInfo technopreneurIt;

  JalurKelulusan({
    required this.skripsiReguler,
    required this.technopreneurIt,
  });

  factory JalurKelulusan.fromJson(Map<String, dynamic> json) {
    return JalurKelulusan(
      skripsiReguler: SkripsiRegulerInfo.fromJson(json['skripsi_reguler'] ?? {}),
      technopreneurIt: TechnopreneurItInfo.fromJson(json['technopreneur_it'] ?? {}),
    );
  }
}

class ProgressKelulusanData {
  final String jenjang;
  final String prodi;
  final int targetSks;
  final int totalSksLulus;
  final int sisaSks;
  final double persentaseKelulusan;
  final int semesterSaatIni;
  final int estimasiSisaSemester;
  final KelayakanWisuda kelayakanAkademikWisuda;
  final JalurKelulusan jalurKelulusan;

  ProgressKelulusanData({
    required this.jenjang,
    required this.prodi,
    required this.targetSks,
    required this.totalSksLulus,
    required this.sisaSks,
    required this.persentaseKelulusan,
    required this.semesterSaatIni,
    required this.estimasiSisaSemester,
    required this.kelayakanAkademikWisuda,
    required this.jalurKelulusan,
  });

  factory ProgressKelulusanData.fromJson(Map<String, dynamic> json) {
    return ProgressKelulusanData(
      jenjang: json['jenjang']?.toString() ?? '',
      prodi: json['prodi']?.toString() ?? '',
      targetSks: int.tryParse(json['target_sks']?.toString() ?? '144') ?? 144,
      totalSksLulus: int.tryParse(json['total_sks_lulus']?.toString() ?? '0') ?? 0,
      sisaSks: int.tryParse(json['sisa_sks']?.toString() ?? '0') ?? 0,
      persentaseKelulusan: double.tryParse(json['persentase_kelulusan']?.toString() ?? '0') ?? 0.0,
      semesterSaatIni: int.tryParse(json['semester_saat_ini']?.toString() ?? '0') ?? 0,
      estimasiSisaSemester: int.tryParse(json['estimasi_sisa_semester']?.toString() ?? '0') ?? 0,
      kelayakanAkademikWisuda: KelayakanWisuda.fromJson(json['kelayakan_akademik_wisuda'] ?? {}),
      jalurKelulusan: JalurKelulusan.fromJson(json['jalur_kelulusan'] ?? {}),
    );
  }
}

class SkkmPoinInfo {
  final int estimasiPoinSkkm;
  final String description;

  SkkmPoinInfo({
    required this.estimasiPoinSkkm,
    required this.description,
  });

  factory SkkmPoinInfo.fromJson(Map<String, dynamic> json) {
    return SkkmPoinInfo(
      estimasiPoinSkkm: int.tryParse(json['estimasi_poin_skkm']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? '',
    );
  }
}

class SkpiData {
  final bool isSkpiEligible;
  final String statusSkpi;
  final SkkmPoinInfo skkmPoinInfo;
  final List<String> peringatanKekurangan;

  SkpiData({
    required this.isSkpiEligible,
    required this.statusSkpi,
    required this.skkmPoinInfo,
    required this.peringatanKekurangan,
  });

  factory SkpiData.fromJson(Map<String, dynamic> json) {
    return SkpiData(
      isSkpiEligible: json['is_skpi_eligible'] == true,
      statusSkpi: json['status_skpi']?.toString() ?? '',
      skkmPoinInfo: SkkmPoinInfo.fromJson(json['skkm_poin_info'] ?? {}),
      peringatanKekurangan: (json['peringatan_kekurangan'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class SimulasiIpkData {
  final double targetIpk;
  final double ipkSaatIni;
  final int sisaSks;
  final double wajibIpsRataRata;
  final bool isAchievable;
  final String analisisKalimat;

  SimulasiIpkData({
    required this.targetIpk,
    required this.ipkSaatIni,
    required this.sisaSks,
    required this.wajibIpsRataRata,
    required this.isAchievable,
    required this.analisisKalimat,
  });

  factory SimulasiIpkData.fromJson(Map<String, dynamic> json) {
    return SimulasiIpkData(
      targetIpk: double.tryParse(json['target_ipk']?.toString() ?? '0') ?? 0.0,
      ipkSaatIni: double.tryParse(json['ipk_saat_ini']?.toString() ?? '0') ?? 0.0,
      sisaSks: int.tryParse(json['sisa_sks']?.toString() ?? '0') ?? 0,
      wajibIpsRataRata: double.tryParse(json['wajib_ips_rata_rata']?.toString() ?? '0') ?? 0.0,
      isAchievable: json['is_achievable'] == true,
      analisisKalimat: json['analisis_kalimat']?.toString() ?? '',
    );
  }
}
