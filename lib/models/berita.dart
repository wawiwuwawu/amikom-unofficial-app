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
  final int nextOffset;
  final int prevOffset;

  Pagination({
    required this.currentPage,
    required this.nextOffset,
    required this.prevOffset,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        currentPage: json['currentPage'] ?? 0,
        nextOffset: json['nextOffset'] ?? 0,
        prevOffset: json['prevOffset'] ?? 0,
      );

  bool get hasMore => nextOffset > 0;
}
