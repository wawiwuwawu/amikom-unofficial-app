class NotifikasiItem {
  final String id;
  final String judul;
  final String tanggal;
  final String detailUrl;

  NotifikasiItem({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.detailUrl,
  });

  factory NotifikasiItem.fromJson(Map<String, dynamic> json) {
    return NotifikasiItem(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      judul: json['judul']?.toString() ?? json['JUDUL']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? json['TANGGAL']?.toString() ?? '',
      detailUrl: json['detail_url']?.toString() ?? '',
    );
  }
}
