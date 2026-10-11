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
  final double ipk;

  Statistik({
    required this.totalSks,
    required this.ipk,
  });

  factory Statistik.fromJson(Map<String, dynamic> json) => Statistik(
        totalSks: json['total_sks'] ?? 0,
        ipk: (json['ipk'] ?? 0).toDouble(),
      );
}

class Status {
  final String status;

  Status({
    required this.status,
  });

  factory Status.fromJson(Map<String, dynamic> json) => Status(
        status: json['status'] ?? '',
      );
}
