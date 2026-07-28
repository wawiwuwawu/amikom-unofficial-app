import 'dart:convert';

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
        judul: (json['JUDUL']?.toString() ?? json['judul']?.toString() ?? '')
            .replaceAll('\u00a0', ' ')
            .replaceAll('&nbsp;', ' ')
            .trim(),
        tanggal: (json['TANGGAL']?.toString() ?? json['tanggal']?.toString() ?? '')
            .replaceAll('\u00a0', ' ')
            .replaceAll('&nbsp;', ' ')
            .trim(),
      );
}

class Lampiran {
  final String nama;
  final String url;

  Lampiran({required this.nama, required this.url});

  factory Lampiran.fromJson(Map<String, dynamic> json) => Lampiran(
        nama: (json['nama']?.toString() ?? json['NAMA']?.toString() ?? 'Lampiran Dokumen')
            .replaceAll('\u00a0', ' ')
            .replaceAll('&nbsp;', ' ')
            .trim(),
        url: (json['url']?.toString() ?? json['URL']?.toString() ?? json['link']?.toString() ?? '')
            .trim(),
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
    
    if (rawJson['data'] != null) {
      if (rawJson['data'] is Map<String, dynamic>) {
        json = rawJson['data'] as Map<String, dynamic>;
      } else if (rawJson['data'] is Map) {
        json = Map<String, dynamic>.from(rawJson['data']);
      } else if (rawJson['data'] is List && (rawJson['data'] as List).isNotEmpty) {
        final firstItem = (rawJson['data'] as List).first;
        if (firstItem is Map) {
          json = Map<String, dynamic>.from(firstItem);
        }
      } else if (rawJson['data'] is String) {
        try {
          final parsed = jsonDecode(rawJson['data']);
          if (parsed is Map) {
            json = Map<String, dynamic>.from(parsed);
          } else if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
            json = Map<String, dynamic>.from(parsed.first);
          }
        } catch (_) {}
      }
    }

    String cleanText(String str) {
      return str.replaceAll('\u00a0', ' ').replaceAll('&nbsp;', ' ').trim();
    }

    List<String> parseKonten(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => cleanText(e.toString()))
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (raw is String && raw.trim().isNotEmpty) {
        return [cleanText(raw)];
      } else if (raw is Map) {
        final text = raw['text'] ?? raw['content'] ?? raw['html'] ?? raw['isi'];
        if (text != null && text.toString().trim().isNotEmpty) {
          return [cleanText(text.toString())];
        }
      }
      return [];
    }

    List<Lampiran> parseLampiran(dynamic raw) {
      if (raw is List) {
        final list = <Lampiran>[];
        for (final item in raw) {
          if (item is Map) {
            list.add(Lampiran.fromJson(Map<String, dynamic>.from(item)));
          } else if (item is String && item.isNotEmpty) {
            list.add(Lampiran(nama: 'Lampiran Dokumen', url: item.trim()));
          }
        }
        return list;
      }
      return [];
    }

    final judul = cleanText(
      json['judul']?.toString() ??
          json['JUDUL']?.toString() ??
          json['title']?.toString() ??
          json['name']?.toString() ??
          '',
    );

    final oleh = cleanText(
      json['oleh']?.toString() ??
          json['OLEH']?.toString() ??
          json['author']?.toString() ??
          json['pengirim']?.toString() ??
          '',
    );

    final pukul = cleanText(
      json['pukul']?.toString() ??
          json['PUKUL']?.toString() ??
          json['tanggal']?.toString() ??
          json['date']?.toString() ??
          '',
    );

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
