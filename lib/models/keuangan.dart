class KeuanganHistoryItem {
  final String tahunAkademik;
  final int semester;
  final int semesterTempuh;
  final int jumlahBayar;
  final String tglBayar;
  final String? nomorKwitansi;
  final String? norefBank;
  final int angsuranKe;
  final String channelBank;
  final int kodeBank;

  KeuanganHistoryItem({
    required this.tahunAkademik,
    required this.semester,
    required this.semesterTempuh,
    required this.jumlahBayar,
    required this.tglBayar,
    this.nomorKwitansi,
    this.norefBank,
    required this.angsuranKe,
    required this.channelBank,
    required this.kodeBank,
  });

  factory KeuanganHistoryItem.fromJson(Map<String, dynamic> json) {
    return KeuanganHistoryItem(
      tahunAkademik: json['tahun_akademik'] ?? '',
      semester: (json['semester'] as num?)?.toInt() ?? 0,
      semesterTempuh: (json['semester_tempuh'] as num?)?.toInt() ?? 0,
      jumlahBayar: (json['jumlah_bayar'] as num?)?.toInt() ?? 0,
      tglBayar: json['tgl_bayar'] ?? '',
      nomorKwitansi: json['nomor_kwitansi'],
      norefBank: json['noref_bank'],
      angsuranKe: (json['angsuran_ke'] as num?)?.toInt() ?? 1,
      channelBank: json['channel_bank'] ?? 'Manual',
      kodeBank: (json['kode_bank'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toDetailRequestBody() {
    return {
      'nomor_kwitansi': nomorKwitansi,
      'tgl_bayar': tglBayar,
      'angsuran_ke': angsuranKe,
      'tahun_akademik': tahunAkademik,
      'semester': semester,
      'kode_bank': kodeBank,
    };
  }

  Map<String, dynamic> toDownloadQueryParams() {
    return {
      if (nomorKwitansi != null) 'nomor_kwitansi': nomorKwitansi,
      'tgl_bayar': tglBayar,
      'angsuran_ke': angsuranKe,
      'tahun_akademik': tahunAkademik,
      'semester': semester,
      'kode_bank': kodeBank,
    };
  }
}

class KeuanganHistoryResponse {
  final int totalBayar;
  final List<KeuanganHistoryItem> data;

  KeuanganHistoryResponse({
    required this.totalBayar,
    required this.data,
  });

  factory KeuanganHistoryResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    return KeuanganHistoryResponse(
      totalBayar: (json['total_bayar'] as num?)?.toInt() ?? 0,
      data: list.map((e) => KeuanganHistoryItem.fromJson(e)).toList(),
    );
  }
}

class KeuanganDetailItem {
  final int nominal;
  final String noReferensi;
  final String jenisBiaya;
  final String tglBayar;
  final String tahunAkademik;
  final int semester;
  final int jenisPembayaran;

  KeuanganDetailItem({
    required this.nominal,
    required this.noReferensi,
    required this.jenisBiaya,
    required this.tglBayar,
    required this.tahunAkademik,
    required this.semester,
    required this.jenisPembayaran,
  });

  factory KeuanganDetailItem.fromJson(Map<String, dynamic> json) {
    return KeuanganDetailItem(
      nominal: (json['nominal'] as num?)?.toInt() ?? 0,
      noReferensi: json['no_referensi'] ?? '',
      jenisBiaya: json['jenis_biaya'] ?? '',
      tglBayar: json['tgl_bayar'] ?? '',
      tahunAkademik: json['tahun_akademik'] ?? '',
      semester: (json['semester'] as num?)?.toInt() ?? 0,
      jenisPembayaran: (json['jenis_pembayaran'] as num?)?.toInt() ?? 0,
    );
  }
}
