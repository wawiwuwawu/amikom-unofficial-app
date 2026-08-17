class TrendSemesterItem {
  final int semester;
  final String tahunAkademik;
  final int sksSemester;
  final double ips;
  final double ipkKumulatif;
  final double delta;

  TrendSemesterItem({
    required this.semester,
    required this.tahunAkademik,
    required this.sksSemester,
    required this.ips,
    required this.ipkKumulatif,
    required this.delta,
  });

  factory TrendSemesterItem.fromJson(Map<String, dynamic> json) {
    return TrendSemesterItem(
      semester: int.tryParse(json['semester']?.toString() ?? '0') ?? 0,
      tahunAkademik: json['tahun_akademik']?.toString() ?? '',
      sksSemester: int.tryParse(json['sks_semester']?.toString() ?? '0') ?? 0,
      ips: double.tryParse(json['ips']?.toString() ?? '0') ?? 0.0,
      ipkKumulatif: double.tryParse(json['ipk_kumulatif']?.toString() ?? '0') ?? 0.0,
      delta: double.tryParse(json['delta']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class HistoriIpkData {
  final double ipkTerakhir;
  final int totalSksLulus;
  final List<TrendSemesterItem> trendSemester;

  HistoriIpkData({
    required this.ipkTerakhir,
    required this.totalSksLulus,
    required this.trendSemester,
  });

  factory HistoriIpkData.fromJson(Map<String, dynamic> json) {
    return HistoriIpkData(
      ipkTerakhir: double.tryParse(json['ipk_terakhir']?.toString() ?? '0') ?? 0.0,
      totalSksLulus: int.tryParse(json['total_sks_lulus']?.toString() ?? '0') ?? 0,
      trendSemester: (json['trend_semester'] as List?)
              ?.map((e) => TrendSemesterItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
