// Model SKKM (Satuan Kredit Kegiatan Mahasiswa) — fitur angkatan 2024+.
//
// Kontrak dari panduan BE 2026-11-01 (§4–§5): semua field opsional portal
// (`bukti`, `id_aktivitas`, `komentar_validator`) bisa absen; `status`
// dikirim portal apa adanya (bukan enum tertutup); untuk angkatan < 2024
// BE menjawab `skkm_berlaku: false` dengan `aktivitas` kosong dan
// `total_poin_valid` null — itu kebijakan kampus, bukan galat.

/// Data penuh `GET /api/v1/skkm`.
class SkkmData {
  final int? angkatan;
  final bool skkmBerlaku;
  final int? totalPoinValid;
  final String panduanUrl;
  final int jumlahAktivitas;

  /// Opsi dropdown langkah 1 alur tambah kegiatan (`{value,label}`).
  final List<SkkmOpsi> opsiUnsur;
  final List<SkkmAktivitas> aktivitas;

  const SkkmData({
    required this.angkatan,
    required this.skkmBerlaku,
    required this.totalPoinValid,
    required this.panduanUrl,
    required this.jumlahAktivitas,
    required this.opsiUnsur,
    required this.aktivitas,
  });

  factory SkkmData.fromJson(Map<String, dynamic> json) {
    bool berlaku;
    final nilai = json['skkm_berlaku'];
    if (nilai is bool) {
      berlaku = nilai;
    } else {
      berlaku = nilai?.toString() == 'true';
    }
    return SkkmData(
      angkatan: json['angkatan'] == null
          ? null
          : int.tryParse(json['angkatan'].toString()),
      skkmBerlaku: berlaku,
      totalPoinValid: json['total_poin_valid'] == null
          ? null
          : int.tryParse(json['total_poin_valid'].toString()),
      panduanUrl: json['panduan_url']?.toString() ?? '',
      jumlahAktivitas:
          int.tryParse(json['jumlah_aktivitas']?.toString() ?? '0') ?? 0,
      opsiUnsur: SkkmOpsi.daftarDari(json['opsi_unsur']),
      aktivitas: (json['aktivitas'] as List?)
              ?.map((e) => SkkmAktivitas.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : Map<String, dynamic>.from(e as Map),
                  ))
              .toList() ??
          const [],
    );
  }
}

/// Satu opsi dropdown rantai (value = kode portal, label = teks tampil).
class SkkmOpsi {
  final String value;
  final String label;

  const SkkmOpsi({required this.value, required this.label});

  factory SkkmOpsi.fromJson(Map<String, dynamic> json) => SkkmOpsi(
        value: json['value']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );

  static List<SkkmOpsi> daftarDari(dynamic data) => (data as List?)
          ?.map((e) => SkkmOpsi.fromJson(
                e is Map<String, dynamic>
                    ? e
                    : Map<String, dynamic>.from(e as Map),
              ))
          .toList() ??
      const [];
}

/// Satu baris aktivitas SKKM dari daftar portal.
class SkkmAktivitas {
  final int no;
  final String unsur;
  final String subUnsur;
  final String level;
  final String jenisKeg;
  final String role;
  final String suratTugas;

  /// Berkas bukti di portal — absen bila portal tidak menampilkannya.
  final SkkmBukti? bukti;
  final int kredit;

  /// Status apa adanya portal ("Valid", "Tidak Valid", dst) — jangan diasumsikan enum.
  final String status;
  final String validator;

  /// Hanya ada pada baris yang bisa dihapus (status "Tidak Valid").
  final String? idAktivitas;
  final String? komentarValidator;

  const SkkmAktivitas({
    required this.no,
    required this.unsur,
    required this.subUnsur,
    required this.level,
    required this.jenisKeg,
    required this.role,
    required this.suratTugas,
    required this.bukti,
    required this.kredit,
    required this.status,
    required this.validator,
    required this.idAktivitas,
    required this.komentarValidator,
  });

  factory SkkmAktivitas.fromJson(Map<String, dynamic> json) {
    final kegiatan =
        (json['kegiatan'] as Map?) ?? const <String, dynamic>{};
    final buktiJson = json['bukti'];
    return SkkmAktivitas(
      no: int.tryParse(json['no']?.toString() ?? '0') ?? 0,
      unsur: kegiatan['unsur']?.toString() ?? '',
      subUnsur: kegiatan['sub_unsur']?.toString() ?? '',
      level: kegiatan['level']?.toString() ?? '',
      jenisKeg: kegiatan['jenis_keg']?.toString() ?? '',
      role: kegiatan['role']?.toString() ?? '',
      suratTugas: kegiatan['surat_tugas']?.toString() ?? '',
      bukti: buktiJson is Map
          ? SkkmBukti.fromJson(
              buktiJson is Map<String, dynamic>
                  ? buktiJson
                  : Map<String, dynamic>.from(buktiJson),
            )
          : null,
      kredit: int.tryParse(json['kredit']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      validator: json['validator']?.toString() ?? '',
      idAktivitas: json['id_aktivitas']?.toString(),
      komentarValidator: json['komentar_validator']?.toString(),
    );
  }
}

/// Berkas bukti di portal. `url`-nya URL portal yang butuh sesi login —
/// tampilkan bukti lewat endpoint proxy unduh BE (`GET /skkm/bukti/:id`),
/// jangan buka [url] langsung dari app.
class SkkmBukti {
  final String id;
  final String url;

  const SkkmBukti({required this.id, required this.url});

  factory SkkmBukti.fromJson(Map<String, dynamic> json) => SkkmBukti(
        id: json['id']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
      );
}

/// Respons `POST /api/v1/skkm/kredit`: poin readonly + id wajib dikirim balik.
class SkkmKredit {
  final int kredit;
  final String idSkkm;

  const SkkmKredit({required this.kredit, required this.idSkkm});

  factory SkkmKredit.fromJson(Map<String, dynamic> json) => SkkmKredit(
        kredit: int.tryParse(json['kredit']?.toString() ?? '0') ?? 0,
        idSkkm: json['id_skkm']?.toString() ?? '',
      );
}
