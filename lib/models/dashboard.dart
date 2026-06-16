class Dashboard {
  final Profile profile;
  final Statistik statistik;
  final Status status;

  Dashboard({
    required this.profile,
    required this.statistik,
    required this.status,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
        profile: Profile.fromJson(json['profile']),
        statistik: Statistik.fromJson(json['statistik']),
        status: Status.fromJson(json['status']),
      );
}

class Profile {
  final String npm;
  final String nama;
  final String noHp;
  final String email;
  final String fakultas;
  final String prodi;
  final int angkatan;
  final String pembimbingAkademik;
  final String fotoUrl;

  Profile({
    required this.npm,
    required this.nama,
    required this.noHp,
    required this.email,
    required this.fakultas,
    required this.prodi,
    required this.angkatan,
    required this.pembimbingAkademik,
    required this.fotoUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        npm: json['npm'] ?? '',
        nama: json['nama'] ?? '',
        noHp: json['no_hp'] ?? '',
        email: json['email'] ?? '',
        fakultas: json['fakultas'] ?? '',
        prodi: json['prodi'] ?? '',
        angkatan: json['angkatan'] ?? 0,
        pembimbingAkademik: json['pembimbing_akademik'] ?? '',
        fotoUrl: json['foto_url'] ?? '',
      );
}

class Statistik {
  final int totalSks;
  final int totalSksMaksimal;
  final double ipk;
  final int sksSekarang;

  Statistik({
    required this.totalSks,
    required this.totalSksMaksimal,
    required this.ipk,
    required this.sksSekarang,
  });

  factory Statistik.fromJson(Map<String, dynamic> json) => Statistik(
        totalSks: json['total_sks'] ?? 0,
        totalSksMaksimal: json['total_sks_maksimal'] ?? 0,
        ipk: (json['ipk'] ?? 0).toDouble(),
        sksSekarang: json['sks_sekarang'] ?? 0,
      );
}

class Status {
  final String status;
  final String masaStudi;
  final String sisaMasaStudi;

  Status({
    required this.status,
    required this.masaStudi,
    required this.sisaMasaStudi,
  });

  factory Status.fromJson(Map<String, dynamic> json) => Status(
        status: json['status'] ?? '',
        masaStudi: json['masa_studi'] ?? '',
        sisaMasaStudi: json['sisa_masa_studi'] ?? '',
      );
}
