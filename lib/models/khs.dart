class KhsOption {
  final String value;
  final String label;

  KhsOption({required this.value, required this.label});

  factory KhsOption.fromJson(Map<String, dynamic> json) => KhsOption(
        value: json['value'] ?? '',
        label: json['label'] ?? '',
      );
}

class KhsItem {
  final String kode;
  final String mkl;
  final int sks;
  final String ambilKe;
  final String nilai;
  final double bobot;

  KhsItem({
    required this.kode,
    required this.mkl,
    required this.sks,
    required this.ambilKe,
    required this.nilai,
    required this.bobot,
  });

  factory KhsItem.fromJson(Map<String, dynamic> json) => KhsItem(
        kode: json['KODE'] ?? '',
        mkl: json['MKL'] ?? '',
        sks: (json['SKS'] ?? 0).toInt(),
        ambilKe: json['AMBILKE'] ?? '',
        nilai: json['NILAI'] ?? '',
        bobot: (json['BOBOT'] ?? 0).toDouble(),
      );
}

class KhsDetailResponse {
  final List<KhsItem> data;
  final bool finishEvaluasi;
  final bool canViewSkripsi;

  KhsDetailResponse({
    required this.data,
    required this.finishEvaluasi,
    required this.canViewSkripsi,
  });

  factory KhsDetailResponse.fromJson(Map<String, dynamic> json) =>
      KhsDetailResponse(
        data: (json['data'] as List?)?.map((e) => KhsItem.fromJson(e)).toList() ?? [],
        finishEvaluasi: json['finish_evaluasi'] ?? false,
        canViewSkripsi: json['can_view_skripsi'] ?? false,
      );
}
