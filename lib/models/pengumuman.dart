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
        id: json['ID'] is int
            ? json['ID']
            : int.tryParse(json['ID']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
        judul: json['JUDUL']?.toString() ?? json['judul']?.toString() ?? '',
        tanggal: json['TANGGAL']?.toString() ?? json['tanggal']?.toString() ?? '',
      );
}

class Lampiran {
  final String nama;
  final String url;

  Lampiran({required this.nama, required this.url});

  factory Lampiran.fromJson(Map<String, dynamic> json) => Lampiran(
        nama: json['nama']?.toString() ?? json['NAMA']?.toString() ?? 'Lampiran',
        url: json['url']?.toString() ?? json['URL']?.toString() ?? json['link']?.toString() ?? '',
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

  factory PengumumanDetail.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;

    List<String> parseKonten(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      } else if (raw is String) {
        if (raw.trim().isEmpty) return [];
        return [raw.trim()];
      }
      return [];
    }

    List<Lampiran> parseLampiran(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => Lampiran.fromJson(e))
            .toList();
      }
      return [];
    }

    return PengumumanDetail(
      judul: json['judul']?.toString() ??
          json['JUDUL']?.toString() ??
          json['title']?.toString() ??
          '',
      oleh: json['oleh']?.toString() ??
          json['OLEH']?.toString() ??
          json['author']?.toString() ??
          json['pengirim']?.toString() ??
          '',
      pukul: json['pukul']?.toString() ??
          json['PUKUL']?.toString() ??
          json['tanggal']?.toString() ??
          json['date']?.toString() ??
          '',
      konten: parseKonten(json['konten'] ?? json['KONTEN'] ?? json['isi'] ?? json['detail']),
      lampiran: parseLampiran(json['lampiran'] ?? json['LAMPIRAN'] ?? json['files']),
    );
  }
}
