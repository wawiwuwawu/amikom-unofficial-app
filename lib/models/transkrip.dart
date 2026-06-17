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
