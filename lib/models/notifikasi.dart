import 'pengumuman.dart'; // Reuse Lampiran model

class NotifikasiItem {
  final String id;
  final String judul;
  final String tanggal;

  NotifikasiItem({
    required this.id,
    required this.judul,
    required this.tanggal,
  });

  factory NotifikasiItem.fromJson(Map<String, dynamic> json) {
    return NotifikasiItem(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      judul: json['judul']?.toString() ?? json['JUDUL']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? json['TANGGAL']?.toString() ?? '',
    );
  }
}

class NotifikasiDetail {
  final String judul;
  final String oleh;
  final String pukul;
  final List<String> konten;
  final List<Lampiran> lampiran;

  NotifikasiDetail({
    required this.judul,
    required this.oleh,
    required this.pukul,
    required this.konten,
    required this.lampiran,
  });

  factory NotifikasiDetail.fromJson(Map<String, dynamic> rawJson) {
    Map<String, dynamic> json = rawJson;

    // Only unwrap 'data' key if it contains expected fields
    final dataVal = rawJson['data'];
    if (dataVal != null) {
      Map<String, dynamic>? candidate;
      if (dataVal is Map) {
        candidate = Map<String, dynamic>.from(dataVal);
      } else if (dataVal is List && dataVal.isNotEmpty && dataVal.first is Map) {
        candidate = Map<String, dynamic>.from(dataVal.first);
      }
      if (candidate != null &&
          (candidate.containsKey('judul') ||
              candidate.containsKey('JUDUL') ||
              candidate.containsKey('konten') ||
              candidate.containsKey('KONTEN') ||
              candidate.containsKey('oleh'))) {
        json = candidate;
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
          json['deskripsi'],
    );

    if (kontenList.isEmpty && json['pengumuman'] != null) {
      kontenList = parseKonten(json['pengumuman']);
    }

    final lampiranList = parseLampiran(
      json['lampiran'] ?? json['LAMPIRAN'] ?? json['files'] ?? json['attachments'],
    );

    return NotifikasiDetail(
      judul: judul,
      oleh: oleh,
      pukul: pukul,
      konten: kontenList,
      lampiran: lampiranList,
    );
  }
}
