class PanduanItem {
  final int id;
  final String judul;
  final String tanggal;
  final String link;

  PanduanItem({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.link,
  });

  factory PanduanItem.fromJson(Map<String, dynamic> json) {
    return PanduanItem(
      id: json['ID'] ?? 0,
      judul: json['JUDUL'] ?? '',
      tanggal: json['TANGGAL'] ?? '',
      link: json['LINK'] ?? '',
    );
  }
}
