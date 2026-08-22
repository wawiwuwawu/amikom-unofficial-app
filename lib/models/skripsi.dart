class SkripsiBimbinganItem {
  final String id;
  final String tanggal;
  final String progres;
  final String keterangan;
  final String? idauto;
  final String? nidn;

  SkripsiBimbinganItem({
    required this.id,
    required this.tanggal,
    required this.progres,
    required this.keterangan,
    this.idauto,
    this.nidn,
  });

  factory SkripsiBimbinganItem.fromJson(Map<String, dynamic> json) {
    return SkripsiBimbinganItem(
      id: json['id']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      progres: json['progres']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
      idauto: json['idauto']?.toString(),
      nidn: json['nidn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': tanggal,
        'progres': progres,
        'keterangan': keterangan,
        if (idauto != null) 'idauto': idauto,
        if (nidn != null) 'nidn': nidn,
      };
}

class SkripsiMainData {
  final List<String> informasi;
  final String? tataCaraDownloadUrl;
  final bool dospemAssigned;
  final String? dospemWarning;
  final String? idauto;
  final String? nidn;
  final List<SkripsiBimbinganItem> bimbingan;

  SkripsiMainData({
    required this.informasi,
    this.tataCaraDownloadUrl,
    required this.dospemAssigned,
    this.dospemWarning,
    this.idauto,
    this.nidn,
    required this.bimbingan,
  });

  factory SkripsiMainData.fromJson(Map<String, dynamic> json) {
    return SkripsiMainData(
      informasi: (json['informasi'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tataCaraDownloadUrl: json['tata_cara_download_url']?.toString(),
      dospemAssigned: json['dospem_assigned'] == true,
      dospemWarning: json['dospem_warning']?.toString(),
      idauto: json['idauto']?.toString(),
      nidn: json['nidn']?.toString(),
      bimbingan: (json['bimbingan'] as List?)
              ?.map((e) => SkripsiBimbinganItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SkripsiProposalItem {
  final int no;
  final String? idProposal;
  final String tglPengajuan;
  final String judul;
  final String? dosen;
  final String status;
  final String? review;

  SkripsiProposalItem({
    required this.no,
    this.idProposal,
    required this.tglPengajuan,
    required this.judul,
    this.dosen,
    required this.status,
    this.review,
  });

  factory SkripsiProposalItem.fromJson(Map<String, dynamic> json) {
    return SkripsiProposalItem(
      no: json['no'] is int
          ? json['no']
          : int.tryParse(json['no']?.toString() ?? '0') ?? 0,
      idProposal: json['id_proposal']?.toString() ?? json['id']?.toString(),
      tglPengajuan: json['tgl_pengajuan']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      dosen: json['dosen']?.toString(),
      status: json['status']?.toString() ?? '',
      review: json['review']?.toString(),
    );
  }
}

class SkripsiPendaftaranItem {
  final String idPengajuan;
  final String judul;
  final String tglDaftar;
  final String? tglUjian;
  final String? ruang;
  final String? jam;
  final int aktivasi;
  final bool canDelete;
  final bool canDownload;

  SkripsiPendaftaranItem({
    required this.idPengajuan,
    required this.judul,
    required this.tglDaftar,
    this.tglUjian,
    this.ruang,
    this.jam,
    required this.aktivasi,
    required this.canDelete,
    required this.canDownload,
  });

  factory SkripsiPendaftaranItem.fromJson(Map<String, dynamic> json) {
    return SkripsiPendaftaranItem(
      idPengajuan: json['id_pengajuan']?.toString() ?? json['id']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      tglDaftar: json['tgldaftar']?.toString() ?? json['tgl_daftar']?.toString() ?? '',
      tglUjian: json['tglujian']?.toString() ?? json['tgl_ujian']?.toString(),
      ruang: json['ruang']?.toString(),
      jam: json['jam']?.toString(),
      aktivasi: json['aktivasi'] is int
          ? json['aktivasi']
          : int.tryParse(json['aktivasi']?.toString() ?? '0') ?? 0,
      canDelete: json['can_delete'] == true,
      canDownload: json['can_download'] == true,
    );
  }
}

class SkripsiPlagiarismeItem {
  final String id;
  final String judulSkripsi;
  final String? fileLaporan;
  final String? laporanHasilCek;
  final String persentase;
  final String status;

  SkripsiPlagiarismeItem({
    required this.id,
    required this.judulSkripsi,
    this.fileLaporan,
    this.laporanHasilCek,
    required this.persentase,
    required this.status,
  });

  factory SkripsiPlagiarismeItem.fromJson(Map<String, dynamic> json) {
    return SkripsiPlagiarismeItem(
      id: json['id']?.toString() ?? '',
      judulSkripsi: json['judul_skripsi']?.toString() ?? '',
      fileLaporan: json['file_laporan']?.toString(),
      laporanHasilCek: json['laporan_hasil_cek']?.toString(),
      persentase: json['persentase']?.toString() ?? '0%',
      status: json['status']?.toString() ?? '',
    );
  }
}
