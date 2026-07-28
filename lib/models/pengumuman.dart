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
        nama: json['nama']?.toString() ?? json['NAMA']?.toString() ?? 'Lampiran Dokumen',
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
    Map<String, dynamic> json = rawJson;
    if (rawJson['data'] is Map<String, dynamic>) {
      json = rawJson['data'] as Map<String, dynamic>;
    }

    List<String> parseKonten(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (raw is String && raw.trim().isNotEmpty) {
        return [raw.trim()];
      } else if (raw is Map) {
        final text = raw['text'] ?? raw['content'] ?? raw['html'] ?? raw['isi'];
        if (text != null && text.toString().trim().isNotEmpty) {
          return [text.toString().trim()];
        }
      }
      return [];
    }

    List<Lampiran> parseLampiran(dynamic raw) {
      if (raw is List) {
        final list = <Lampiran>[];
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            list.add(Lampiran.fromJson(item));
          } else if (item is String && item.isNotEmpty) {
            list.add(Lampiran(nama: 'Lampiran', url: item));
          }
        }
        return list;
      }
      return [];
    }

    final judul = json['judul']?.toString() ??
        json['JUDUL']?.toString() ??
        json['title']?.toString() ??
        json['name']?.toString() ??
        '';

    final oleh = json['oleh']?.toString() ??
        json['OLEH']?.toString() ??
        json['author']?.toString() ??
        json['pengirim']?.toString() ??
        '';

    final pukul = json['pukul']?.toString() ??
        json['PUKUL']?.toString() ??
        json['tanggal']?.toString() ??
        json['date']?.toString() ??
        '';

    var kontenList = parseKonten(
      json['konten'] ??
          json['KONTEN'] ??
          json['isi'] ??
          json['detail'] ??
          json['deskripsi'] ??
          json['body'] ??
          json['content'] ??
          json['html'] ??
          json['text'],
    );

    // Fallback if konten is empty but rawJson has nested details
    if (kontenList.isEmpty && json['pengumuman'] != null) {
      kontenList = parseKonten(json['pengumuman']);
    }

    final lampiranList = parseLampiran(
      json['lampiran'] ?? json['LAMPIRAN'] ?? json['files'] ?? json['attachments'],
    );

    return PengumumanDetail(
      judul: judul,
      oleh: oleh,
      pukul: pukul,
      konten: kontenList,
      lampiran: lampiranList,
    );
  }
}
