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
        bobot: (json['BOBOT'] ?? 0).toDouble(),
        nilai: json['NILAI'] ?? '',
        totalBobot: (json['TOTAL_BOBOT'] ?? 0).toDouble(),
      );
}
