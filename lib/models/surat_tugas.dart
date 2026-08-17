class DosenPendampingOption {
  final String nik;
  final String nama;

  DosenPendampingOption({
    required this.nik,
    required this.nama,
  });

  factory DosenPendampingOption.fromJson(Map<String, dynamic> json) {
    return DosenPendampingOption(
      nik: json['nik']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
    );
  }
}

class JenisKegiatanOption {
  final String value;
  final String label;

  JenisKegiatanOption({
    required this.value,
    required this.label,
  });

  factory JenisKegiatanOption.fromJson(Map<String, dynamic> json) {
    return JenisKegiatanOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class SuratTugasOptions {
  final List<DosenPendampingOption> dosenPendamping;
  final List<JenisKegiatanOption> jenisKegiatan;

  SuratTugasOptions({
    required this.dosenPendamping,
    required this.jenisKegiatan,
  });

  factory SuratTugasOptions.fromJson(Map<String, dynamic> json) {
    return SuratTugasOptions(
      dosenPendamping: (json['dosen_pendamping'] as List?)
              ?.map((e) => DosenPendampingOption.fromJson(e))
              .toList() ??
          [],
      jenisKegiatan: (json['jenis_kegiatan'] as List?)
              ?.map((e) => JenisKegiatanOption.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SearchMahasiswaItem {
  final String label;
  final String value;
  final String npm;
  final String nama;

  SearchMahasiswaItem({
    required this.label,
    required this.value,
    required this.npm,
    required this.nama,
  });

  factory SearchMahasiswaItem.fromJson(Map<String, dynamic> json) {
    return SearchMahasiswaItem(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      npm: json['npm']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
    );
  }
}

class SuratTugasMember {
  final String npm;
  final String nama;

  SuratTugasMember({
    required this.npm,
    required this.nama,
  });

  factory SuratTugasMember.fromJson(Map<String, dynamic> json) {
    return SuratTugasMember(
      npm: json['npm']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
    );
  }
}

class SuratTugasItem {
  final String idSurat;
  final String tglPengajuan;
  final String thnAjaranSmt;
  final String namaKegiatan;
  final String penyelenggara;
  final String tglMulai;
  final String tglSelesai;
  final String bentukKegiatan;
  final String linkKegiatan;
  final String nikPendamping;
  final String pendamping;
  final String jenisKegiatan;
  final String status;
  final String? komentar;
  final bool canEdit;
  final bool canDelete;

  SuratTugasItem({
    required this.idSurat,
    required this.tglPengajuan,
    required this.thnAjaranSmt,
    required this.namaKegiatan,
    required this.penyelenggara,
    required this.tglMulai,
    required this.tglSelesai,
    required this.bentukKegiatan,
    required this.linkKegiatan,
    required this.nikPendamping,
    required this.pendamping,
    required this.jenisKegiatan,
    required this.status,
    this.komentar,
    required this.canEdit,
    required this.canDelete,
  });

  factory SuratTugasItem.fromJson(Map<String, dynamic> json) {
    return SuratTugasItem(
      idSurat: json['id_surat']?.toString() ?? '',
      tglPengajuan: json['tgl_pengajuan']?.toString() ?? '',
      thnAjaranSmt: json['thn_ajaran_smt']?.toString() ?? '',
      namaKegiatan: json['nama_kegiatan']?.toString() ?? json['nama_keg']?.toString() ?? '',
      penyelenggara: json['penyelenggara']?.toString() ?? '',
      tglMulai: json['tgl_mulai']?.toString() ?? json['tanggal_mulai']?.toString() ?? '',
      tglSelesai: json['tgl_selesai']?.toString() ?? json['tanggal_selesai']?.toString() ?? '',
      bentukKegiatan: json['bentuk_kegiatan']?.toString() ?? json['bentuk_keg']?.toString() ?? '',
      linkKegiatan: json['link_kegiatan']?.toString() ?? '',
      nikPendamping: json['nik_pendamping']?.toString() ?? json['dosen_pendamping']?.toString() ?? '',
      pendamping: json['pendamping']?.toString() ?? '',
      jenisKegiatan: json['jenis_kegiatan']?.toString() ?? json['jenis_keg']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      komentar: json['komentar']?.toString(),
      canEdit: json['can_edit'] == true,
      canDelete: json['can_delete'] == true,
    );
  }
}

class SuratTugasData {
  final SuratTugasOptions options;
  final List<String> keteranganBaa;
  final List<SuratTugasItem> items;

  SuratTugasData({
    required this.options,
    required this.keteranganBaa,
    required this.items,
  });

  factory SuratTugasData.fromJson(Map<String, dynamic> json) {
    return SuratTugasData(
      options: SuratTugasOptions.fromJson(json['options'] ?? {}),
      keteranganBaa: (json['keterangan_baa'] as List?)?.map((e) => e.toString()).toList() ?? [],
      items: (json['items'] as List?)?.map((e) => SuratTugasItem.fromJson(e)).toList() ?? [],
    );
  }
}
