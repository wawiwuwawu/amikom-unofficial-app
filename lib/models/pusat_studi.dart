class PusatStudi {
  final String id;
  final String nama;
  final String detailId;
  final String? grupWa;

  PusatStudi({
    required this.id,
    required this.nama,
    required this.detailId,
    this.grupWa,
  });

  factory PusatStudi.fromJson(Map<String, dynamic> json) {
    return PusatStudi(
      id: json['id']?.toString() ?? '',
      nama: json['nama'] ?? '',
      detailId: json['detail_id'] ?? '',
      grupWa: json['grup_wa'],
    );
  }
}

class PusatStudiDetail {
  final ProfilPusatStudi profil;
  final List<DosenPusatStudi> dosen;
  final List<MahasiswaPusatStudi> mahasiswa;
  final List<TemaPusatStudi> tema;

  PusatStudiDetail({
    required this.profil,
    required this.dosen,
    required this.mahasiswa,
    required this.tema,
  });

  factory PusatStudiDetail.fromJson(Map<String, dynamic> json) {
    return PusatStudiDetail(
      profil: ProfilPusatStudi.fromJson(json['profil'] ?? {}),
      dosen: (json['dosen'] as List?)?.map((e) => DosenPusatStudi.fromJson(e)).toList() ?? [],
      mahasiswa: (json['mahasiswa'] as List?)?.map((e) => MahasiswaPusatStudi.fromJson(e)).toList() ?? [],
      tema: (json['tema'] as List?)?.map((e) => TemaPusatStudi.fromJson(e)).toList() ?? [],
    );
  }
}

class ProfilPusatStudi {
  final String nama;
  final String keterangan;

  ProfilPusatStudi({required this.nama, required this.keterangan});

  factory ProfilPusatStudi.fromJson(Map<String, dynamic> json) {
    return ProfilPusatStudi(
      nama: json['nama'] ?? '',
      keterangan: json['keterangan'] ?? '',
    );
  }
}

class DosenPusatStudi {
  final String no;
  final String nik;
  final String nama;

  DosenPusatStudi({required this.no, required this.nik, required this.nama});

  factory DosenPusatStudi.fromJson(Map<String, dynamic> json) {
    return DosenPusatStudi(
      no: json['no']?.toString() ?? '',
      nik: json['nik']?.toString() ?? '',
      nama: json['nama'] ?? '',
    );
  }
}

class MahasiswaPusatStudi {
  final String no;
  final String npm;
  final String nama;
  final String tanggalJoin;

  MahasiswaPusatStudi({required this.no, required this.npm, required this.nama, required this.tanggalJoin});

  factory MahasiswaPusatStudi.fromJson(Map<String, dynamic> json) {
    return MahasiswaPusatStudi(
      no: json['no']?.toString() ?? '',
      npm: json['npm'] ?? '',
      nama: json['nama'] ?? '',
      tanggalJoin: json['tanggal_join'] ?? '',
    );
  }
}

class TemaPusatStudi {
  final String no;
  final String namaTema;
  final String idTema;
  final String judulTema;
  final String deskripsi;
  final String pengusul;
  final String jenisTema;
  final String kuota;

  TemaPusatStudi({
    required this.no, required this.namaTema, required this.idTema, required this.judulTema,
    required this.deskripsi, required this.pengusul, required this.jenisTema, required this.kuota
  });

  factory TemaPusatStudi.fromJson(Map<String, dynamic> json) {
    return TemaPusatStudi(
      no: json['no']?.toString() ?? '',
      namaTema: json['nama_tema'] ?? '',
      idTema: json['id_tema']?.toString() ?? '',
      judulTema: json['judul_tema'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      pengusul: json['pengusul'] ?? '',
      jenisTema: (json['jenis_tema']?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim(),
      kuota: (json['kuota']?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim(),
    );
  }
}

class JoinedDetailTema {
  final String no;
  final String namaTema;
  final String idTema;
  final String judulTema;
  final String deskripsi;
  final String pengusul;
  final String kuota;
  final bool isFull;
  final bool canChoose;
  final bool isProposed;
  final String idAjuan;
  final String statusText;

  JoinedDetailTema({
    required this.no, required this.namaTema, required this.idTema, required this.judulTema,
    required this.deskripsi, required this.pengusul, required this.kuota, required this.isFull,
    required this.canChoose, required this.isProposed, required this.idAjuan, required this.statusText
  });

  factory JoinedDetailTema.fromJson(Map<String, dynamic> json) {
    return JoinedDetailTema(
      no: json['no']?.toString() ?? '',
      namaTema: json['nama_tema'] ?? '',
      idTema: json['id_tema']?.toString() ?? '',
      judulTema: json['judul_tema'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      pengusul: json['pengusul'] ?? '',
      kuota: (json['kuota']?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim(),
      isFull: json['is_full'] == true,
      canChoose: json['can_choose'] == true,
      isProposed: json['is_proposed'] == true,
      idAjuan: json['id_ajuan']?.toString() ?? '',
      statusText: json['status_text'] ?? '',
    );
  }
}
