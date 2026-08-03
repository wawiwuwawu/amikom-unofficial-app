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

class KeuanganTagihanItem {
  final int no;
  final String tahunAkademik;
  final String jenisPembayaran;
  final int nominal;
  final String keterangan;
  final String jenisId;
  final String idtrans;

  KeuanganTagihanItem({
    required this.no,
    required this.tahunAkademik,
    required this.jenisPembayaran,
    required this.nominal,
    required this.keterangan,
    required this.jenisId,
    required this.idtrans,
  });

  factory KeuanganTagihanItem.fromJson(Map<String, dynamic> json) {
    return KeuanganTagihanItem(
      no: (json['no'] as num?)?.toInt() ?? 0,
      tahunAkademik: json['tahun_akademik'] ?? '',
      jenisPembayaran: json['jenis_pembayaran'] ?? '',
      nominal: (json['nominal'] as num?)?.toInt() ?? 0,
      keterangan: json['keterangan'] ?? '',
      jenisId: json['jenis_id']?.toString() ?? '',
      idtrans: json['idtrans']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toBayarPayload() {
    return {
      'idtrans': idtrans,
      'jenis': jenisId,
      'nominal': nominal,
    };
  }
}

class KeuanganActiveTransaction {
  final bool hasActive;
  final String channelBank;
  final String va;
  final int totalNominal;
  final List<dynamic> items;

  KeuanganActiveTransaction({
    required this.hasActive,
    this.channelBank = '',
    this.va = '',
    this.totalNominal = 0,
    this.items = const [],
  });

  factory KeuanganActiveTransaction.fromJson(Map<String, dynamic> json) {
    return KeuanganActiveTransaction(
      hasActive: json['has_active'] ?? false,
      channelBank: json['channel_bank'] ?? '',
      va: json['va'] ?? '',
      totalNominal: (json['total_nominal'] as num?)?.toInt() ?? 0,
      items: json['items'] as List? ?? [],
    );
  }
}

class KeuanganTagihanResponse {
  final int totalTagihan;
  final List<KeuanganTagihanItem> data;
  final KeuanganActiveTransaction activeTransaction;

  KeuanganTagihanResponse({
    required this.totalTagihan,
    required this.data,
    required this.activeTransaction,
  });

  factory KeuanganTagihanResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    return KeuanganTagihanResponse(
      totalTagihan: (json['total_tagihan'] as num?)?.toInt() ?? 0,
      data: list.map((e) => KeuanganTagihanItem.fromJson(e)).toList(),
      activeTransaction: KeuanganActiveTransaction.fromJson(
        json['active_transaction'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class KeuanganVaItem {
  final String tahunAkademik;
  final int semester;
  final String jenisPembayaran;
  final String va;
  final String idtrans;
  final int nominal;

  KeuanganVaItem({
    required this.tahunAkademik,
    required this.semester,
    required this.jenisPembayaran,
    required this.va,
    required this.idtrans,
    required this.nominal,
  });

  factory KeuanganVaItem.fromJson(Map<String, dynamic> json) {
    return KeuanganVaItem(
      tahunAkademik: json['tahun_akademik'] ?? '',
      semester: (json['semester'] as num?)?.toInt() ?? 0,
      jenisPembayaran: json['jenis_pembayaran'] ?? '',
      va: json['va'] ?? '',
      idtrans: json['idtrans']?.toString() ?? '',
      nominal: (json['nominal'] as num?)?.toInt() ?? 0,
    );
  }
}

class KeuanganVaResult {
  final String message;
  final String channelBank;
  final String va;
  final int totalNominal;
  final List<KeuanganVaItem> items;

  KeuanganVaResult({
    required this.message,
    this.channelBank = '',
    this.va = '',
    this.totalNominal = 0,
    this.items = const [],
  });

  factory KeuanganVaResult.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    return KeuanganVaResult(
      message: json['message'] ?? '',
      channelBank: json['channel_bank'] ?? '',
      va: json['va'] ?? '',
      totalNominal: (json['total_nominal'] as num?)?.toInt() ?? 0,
      items: list.map((e) => KeuanganVaItem.fromJson(e)).toList(),
    );
  }
}
