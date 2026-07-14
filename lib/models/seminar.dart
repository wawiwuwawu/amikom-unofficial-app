class Seminar {
  final String judul;
  final String npm;
  final String nama;
  final String prodi;
  final String idPengajuan;
  final String tglUjian;
  final String hari;
  final String ruang;
  final String jam;

  Seminar({
    required this.judul,
    required this.npm,
    required this.nama,
    required this.prodi,
    required this.idPengajuan,
    required this.tglUjian,
    required this.hari,
    required this.ruang,
    required this.jam,
  });

  factory Seminar.fromJson(Map<String, dynamic> json) => Seminar(
        judul: json['judul'] ?? '',
        npm: json['npm'] ?? '',
        nama: json['nama'] ?? '',
        prodi: json['prodi'] ?? '',
        idPengajuan: json['id_pengajuan']?.toString() ?? '',
        tglUjian: json['tglujian'] ?? '',
        hari: json['hari'] ?? '',
        ruang: json['ruang'] ?? '',
        jam: json['jam'] ?? '',
      );
}
