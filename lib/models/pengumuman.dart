class PengumumanItem {
  final int id;
  final String judul;
  final String tanggal;

  PengumumanItem({
    required this.id,
    required this.judul,
    required this.tanggal,
  });

  factory PengumumanItem.fromJson(Map<String, dynamic> json) => PengumumanItem(
        id: json['ID'] ?? 0,
        judul: json['JUDUL'] ?? '',
        tanggal: json['TANGGAL'] ?? '',
      );
}

class Lampiran {
  final String nama;
  final String url;

  Lampiran({required this.nama, required this.url});

  factory Lampiran.fromJson(Map<String, dynamic> json) => Lampiran(
        nama: json['nama'] ?? '',
        url: json['url'] ?? '',
      );
}

class PengumumanDetail {
  final String judul;
  final String oleh;
  final String pukul;
  final List<String> konten;
  final List<Lampiran> lampiran;

  PengumumanDetail({
    required this.judul,
    required this.oleh,
    required this.pukul,
    required this.konten,
    required this.lampiran,
  });

  factory PengumumanDetail.fromJson(Map<String, dynamic> json) =>
      PengumumanDetail(
        judul: json['judul'] ?? '',
        oleh: json['oleh'] ?? '',
        pukul: json['pukul'] ?? '',
        konten: (json['konten'] as List?)?.map((e) => e.toString()).toList() ?? [],
        lampiran: (json['lampiran'] as List?)
                ?.map((e) => Lampiran.fromJson(e))
                .toList() ??
            [],
      );
}
