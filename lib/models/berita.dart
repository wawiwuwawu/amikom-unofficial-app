class Berita {
  final String id;
  final String judul;
  final String author;
  final String tanggal;
  final String gambar;
  final String excerpt;

  Berita({
    required this.id,
    required this.judul,
    required this.author,
    required this.tanggal,
    required this.gambar,
    required this.excerpt,
  });

  factory Berita.fromJson(Map<String, dynamic> json) => Berita(
        id: json['id'] ?? '',
        judul: json['judul'] ?? '',
        author: json['author'] ?? '',
        tanggal: json['tanggal'] ?? '',
        gambar: json['gambar'] ?? '',
        excerpt: json['excerpt'] ?? '',
      );
}

class BeritaDetail {
  final String id;
  final String judul;
  final String author;
  final String tanggal;
  final String gambar;
  final String konten;

  BeritaDetail({
    required this.id,
    required this.judul,
    required this.author,
    required this.tanggal,
    required this.gambar,
    required this.konten,
  });

  factory BeritaDetail.fromJson(Map<String, dynamic> json) => BeritaDetail(
        id: json['id'] ?? '',
        judul: json['judul'] ?? '',
        author: json['author'] ?? '',
        tanggal: json['tanggal'] ?? '',
        gambar: json['gambar'] ?? '',
        konten: json['konten'] ?? '',
      );
}

class Pagination {
  final int currentPage;
  final int? nextOffset;
  final int? prevOffset;

  Pagination({
    required this.currentPage,
    this.nextOffset,
    this.prevOffset,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        currentPage: json['currentPage'] is num
            ? (json['currentPage'] as num).toInt()
            : int.tryParse(json['currentPage']?.toString() ?? '') ?? 0,
        nextOffset: json['nextOffset'] is num
            ? (json['nextOffset'] as num).toInt()
            : (json['nextOffset'] != null ? int.tryParse(json['nextOffset'].toString()) : null),
        prevOffset: json['prevOffset'] is num
            ? (json['prevOffset'] as num).toInt()
            : (json['prevOffset'] != null ? int.tryParse(json['prevOffset'].toString()) : null),
      );

  bool get hasMore => nextOffset != null && nextOffset! > 0;
}
