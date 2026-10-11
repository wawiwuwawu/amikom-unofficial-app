/// Hasil endpoint `POST /api/v1/absensi/auto-validasi`.
///
/// Mode `inspeksi` hanya memeriksa (dry run) dan mode `tulis` benar-benar
/// menulis validasi lewat portal. Status pertemuan bisa `sukses`, `gagal`,
/// atau `dilewati` — `dilewati` BUKAN kesalahan.
class AutoValidasiResult {
  final AutoValidasiRingkasan ringkasan;
  final List<AutoValidasiPertemuan> pertemuan;

  AutoValidasiResult({
    AutoValidasiRingkasan? ringkasan,
    this.pertemuan = const [],
  }) : ringkasan = ringkasan ?? AutoValidasiRingkasan();

  factory AutoValidasiResult.fromJson(Map<String, dynamic> json) {
    final rawRingkasan = json['ringkasan'];
    return AutoValidasiResult(
      ringkasan: rawRingkasan is Map
          ? AutoValidasiRingkasan.fromJson(Map<String, dynamic>.from(rawRingkasan))
          : AutoValidasiRingkasan(),
      pertemuan: (json['pertemuan'] as List?)
              ?.map((e) => AutoValidasiPertemuan.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}

/// Mode eksekusi auto-validasi; wire value dikirim apa adanya ke portal.
enum AutoValidasiMode {
  inspeksi('inspeksi'),
  tulis('tulis');

  const AutoValidasiMode(this.wire);
  final String wire;
}

class AutoValidasiRingkasan {
  final int total;
  final int sukses;
  final int gagal;
  final int dilewati;
  final bool dryRun;

  AutoValidasiRingkasan({
    this.total = 0,
    this.sukses = 0,
    this.gagal = 0,
    this.dilewati = 0,
    this.dryRun = false,
  });

  factory AutoValidasiRingkasan.fromJson(Map<String, dynamic> json) =>
      AutoValidasiRingkasan(
        total: _toInt(json['total']),
        sukses: _toInt(json['sukses']),
        gagal: _toInt(json['gagal']),
        dilewati: _toInt(json['dilewati']),
        dryRun: json['dry_run'] == true,
      );
}

class AutoValidasiPertemuan {
  final String makul;
  final String tanggal;
  final String idPresensiDosen;
  final String idPresensiMhs;
  final String jenis;
  final String status;
  final String alasan;
  final int jumlahAsdos;
  final Map<String, dynamic> payload;

  AutoValidasiPertemuan({
    required this.makul,
    this.tanggal = '',
    required this.idPresensiDosen,
    required this.idPresensiMhs,
    required this.jenis,
    required this.status,
    required this.alasan,
    this.jumlahAsdos = 0,
    this.payload = const {},
  });

  factory AutoValidasiPertemuan.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return AutoValidasiPertemuan(
      makul: json['makul']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      idPresensiDosen: json['id_presensi_dosen']?.toString() ?? '',
      idPresensiMhs: json['id_presensi_mhs']?.toString() ?? '',
      jenis: json['jenis']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      alasan: json['alasan']?.toString() ?? '',
      jumlahAsdos: _toInt(json['jumlah_asdos']),
      payload: rawPayload is Map
          ? Map<String, dynamic>.from(rawPayload)
          : const {},
    );
  }
}

/// `int` aman dari int/double/String, sama seperti pola model lain.
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}
