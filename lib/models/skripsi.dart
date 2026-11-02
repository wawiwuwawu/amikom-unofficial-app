class SkripsiBimbinganItem {
  final String id;
  final String tanggal;
  final String progres;
  final String keterangan;
  final String? idauto;
  final String? nidn;
  // Kontrak BE Nov 2026: daftar bimbingan kini mencakup SEMUA dosbim
  // (array flat). Field null pada bentuk halaman lama.
  final String? pembimbing;
  final int? urutanPembimbing;
  final String? status;
  final String? komentar;

  SkripsiBimbinganItem({
    required this.id,
    required this.tanggal,
    required this.progres,
    required this.keterangan,
    this.idauto,
    this.nidn,
    this.pembimbing,
    this.urutanPembimbing,
    this.status,
    this.komentar,
  });

  factory SkripsiBimbinganItem.fromJson(Map<String, dynamic> json) {
    return SkripsiBimbinganItem(
      id: json['id']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      progres: json['progres']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
      idauto: json['idauto']?.toString(),
      nidn: json['nidn']?.toString(),
      pembimbing: json['pembimbing']?.toString(),
      urutanPembimbing: json['urutan_pembimbing'] is int
          ? json['urutan_pembimbing'] as int
          : int.tryParse(json['urutan_pembimbing']?.toString() ?? ''),
      status: json['status']?.toString(),
      komentar: json['komentar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': tanggal,
        'progres': progres,
        'keterangan': keterangan,
        if (idauto != null) 'idauto': idauto,
        if (nidn != null) 'nidn': nidn,
        if (pembimbing != null) 'pembimbing': pembimbing,
        if (urutanPembimbing != null) 'urutan_pembimbing': urutanPembimbing,
        if (status != null) 'status': status,
        if (komentar != null) 'komentar': komentar,
      };
}

/// Metadata satu dosen pembimbing dari tab Kartu Bimbingan (kontrak BE
/// Nov 2026 §1). Sumber `idauto`/`nidn` untuk form tambah bimbingan per
/// dosbim — untuk dosbim kedua BE tidak menyediakannya di top-level.
class SkripsiDosbim {
  final int? urutan;
  final String? label;
  final String nama;
  final String? idauto;
  final String? nidn;
  final String? pesanBimbingan;

  SkripsiDosbim({
    this.urutan,
    this.label,
    required this.nama,
    this.idauto,
    this.nidn,
    this.pesanBimbingan,
  });

  factory SkripsiDosbim.fromJson(Map<String, dynamic> json) {
    return SkripsiDosbim(
      urutan: json['urutan'] is int
          ? json['urutan'] as int
          : int.tryParse(json['urutan']?.toString() ?? ''),
      label: json['label']?.toString(),
      nama: json['nama']?.toString() ?? '',
      idauto: json['idauto']?.toString(),
      nidn: json['nidn']?.toString(),
      pesanBimbingan: json['pesan_bimbingan']?.toString(),
    );
  }
}

/// Status ajuan proposal dari kotak alert tab Proposal (kontrak BE
/// Nov 2026 §1).
class SkripsiStatusProposal {
  final bool layak;
  final String? pesan;
  final String? komentarPusatStudi;
  final String? reviewer;

  SkripsiStatusProposal({
    required this.layak,
    this.pesan,
    this.komentarPusatStudi,
    this.reviewer,
  });

  factory SkripsiStatusProposal.fromJson(Map<String, dynamic> json) {
    return SkripsiStatusProposal(
      layak: json['layak'] == true,
      pesan: json['pesan']?.toString(),
      komentarPusatStudi: json['komentar_pusat_studi']?.toString(),
      reviewer: json['reviewer']?.toString(),
    );
  }
}

class SkripsiMainData {
  final List<String> informasi;
  final String? tataCaraDownloadUrl;
  final bool dospemAssigned;
  final String? dospemWarning;
  final String? idauto;
  final String? nidn;
  final List<SkripsiBimbinganItem> bimbingan;
  // Kontrak BE Nov 2026 §1 — null/[] pada bentuk halaman lama.
  final List<SkripsiDosbim> pembimbing;
  final SkripsiStatusProposal? statusProposal;
  final List<String> peringatanAccUjian;
  final List<String> peringatanAccPlagiarisme;

  SkripsiMainData({
    required this.informasi,
    this.tataCaraDownloadUrl,
    required this.dospemAssigned,
    this.dospemWarning,
    this.idauto,
    this.nidn,
    required this.bimbingan,
    this.pembimbing = const [],
    this.statusProposal,
    this.peringatanAccUjian = const [],
    this.peringatanAccPlagiarisme = const [],
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
      pembimbing: (json['pembimbing'] as List?)
              ?.map((e) => SkripsiDosbim.fromJson(e))
              .toList() ??
          [],
      statusProposal: json['status_proposal'] is Map<String, dynamic>
          ? SkripsiStatusProposal.fromJson(
              json['status_proposal'] as Map<String, dynamic>)
          : null,
      peringatanAccUjian: (json['peringatan_acc_ujian'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      peringatanAccPlagiarisme:
          (json['peringatan_acc_plagiarisme'] as List?)
                  ?.map((e) => e.toString())
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
  final String? laporanHasilCek;
  final String persentase;
  final String status;

  SkripsiPlagiarismeItem({
    required this.id,
    required this.judulSkripsi,
    this.laporanHasilCek,
    required this.persentase,
    required this.status,
  });

  factory SkripsiPlagiarismeItem.fromJson(Map<String, dynamic> json) {
    return SkripsiPlagiarismeItem(
      id: json['id']?.toString() ?? '',
      judulSkripsi: json['judul_skripsi']?.toString() ?? '',
      laporanHasilCek: json['laporan_hasil_cek']?.toString(),
      persentase: json['persentase']?.toString() ?? '0%',
      status: json['status']?.toString() ?? '',
    );
  }
}
