/// Model biodata mahasiswa (`GET /api/v1/biodata`).
///
/// Kontrak BE 2026-11-11: data terdiri dari `data_diri`, `alamat`,
/// `pendidikan` (sd/smp/sma), `orang_tua` (ayah/ibu) dan `foto_url`.
/// Field kosong dari portal berbentuk `""` dan tanggal lahir bisa `NULL` —
/// penyaji (ProfilPage) yang menerjemahkan kosong/null menjadi "-".
///
/// PII: model ini hanya hidup di memori — JANGAN di-cache ke disk dan JANGAN
/// diplog (aturan §0.5).
class Biodata {
  final BiodataDataDiri dataDiri;
  final BiodataAlamat alamat;
  final BiodataPendidikan pendidikan;
  final BiodataOrangTua orangTua;
  final String fotoUrl;

  const Biodata({
    required this.dataDiri,
    required this.alamat,
    required this.pendidikan,
    required this.orangTua,
    required this.fotoUrl,
  });

  factory Biodata.fromJson(Map<String, dynamic> json) => Biodata(
        dataDiri: BiodataDataDiri.fromJson(_mapOf(json['data_diri'])),
        alamat: BiodataAlamat.fromJson(_mapOf(json['alamat'])),
        pendidikan: BiodataPendidikan.fromJson(_mapOf(json['pendidikan'])),
        orangTua: BiodataOrangTua.fromJson(_mapOf(json['orang_tua'])),
        fotoUrl: _str(json, 'foto_url'),
      );

  static Map<String, dynamic> _mapOf(dynamic raw) =>
      raw is Map<String, dynamic> ? raw : const <String, dynamic>{};

  static String _str(Map<String, dynamic> j, String key) =>
      j[key]?.toString() ?? '';
}

/// Pilihan berbentuk `{kode, label}` (jenis kelamin, agama). Tampilan memakai
/// [label]; portal kadang mengirim string langsung — tetap diterima.
class BiodataPilihan {
  final String kode;
  final String label;

  const BiodataPilihan({this.kode = '', this.label = ''});

  factory BiodataPilihan.fromJson(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return BiodataPilihan(
        kode: raw['kode']?.toString() ?? '',
        label: raw['label']?.toString() ?? '',
      );
    }
    return BiodataPilihan(label: raw?.toString() ?? '');
  }
}

class BiodataDataDiri {
  final String nama;
  final String nikktp;
  final String tempatLahir;

  /// `yyyy-MM-dd` dari BE; bisa NULL/kosong (biodata portal belum diisi).
  final String? tanggalLahir;
  final BiodataPilihan jenisKelamin;
  final BiodataPilihan agama;
  final String statusPerkawinan;
  final String jumlahAnak;
  final String email;
  final String noHp;
  final String nisn;

  const BiodataDataDiri({
    required this.nama,
    required this.nikktp,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.agama,
    required this.statusPerkawinan,
    required this.jumlahAnak,
    required this.email,
    required this.noHp,
    required this.nisn,
  });

  factory BiodataDataDiri.fromJson(Map<String, dynamic> json) =>
      BiodataDataDiri(
        nama: _str(json, 'nama'),
        nikktp: _str(json, 'nikktp'),
        tempatLahir: _str(json, 'tempat_lahir'),
        tanggalLahir: _tanggal(json['tanggal_lahir']),
        jenisKelamin: BiodataPilihan.fromJson(json['jenis_kelamin']),
        agama: BiodataPilihan.fromJson(json['agama']),
        statusPerkawinan: _str(json, 'status_perkawinan'),
        jumlahAnak: _str(json, 'jumlah_anak'),
        email: _str(json, 'email'),
        noHp: _str(json, 'no_hp'),
        nisn: _str(json, 'nisn'),
      );

  static String _str(Map<String, dynamic> j, String key) =>
      j[key]?.toString() ?? '';

  /// NULL dan "" sama-sama dinormalisasi ke null — penyaji cukup cek null.
  static String? _tanggal(dynamic raw) {
    final v = raw?.toString() ?? '';
    return v.isEmpty ? null : v;
  }
}

class BiodataAlamat {
  final String alamat;
  final String rt;
  final String rw;
  final String kecamatan;
  final String kabupaten;
  final String propinsi;
  final String kodePos;

  const BiodataAlamat({
    required this.alamat,
    required this.rt,
    required this.rw,
    required this.kecamatan,
    required this.kabupaten,
    required this.propinsi,
    required this.kodePos,
  });

  factory BiodataAlamat.fromJson(Map<String, dynamic> json) => BiodataAlamat(
        alamat: _str(json, 'alamat'),
        rt: _str(json, 'rt'),
        rw: _str(json, 'rw'),
        kecamatan: _str(json, 'kecamatan'),
        kabupaten: _str(json, 'kabupaten'),
        propinsi: _str(json, 'propinsi'),
        kodePos: _str(json, 'kode_pos'),
      );

  static String _str(Map<String, dynamic> j, String key) =>
      j[key]?.toString() ?? '';
}

/// Satu jenjang sekolah (sd/smp/sma).
class BiodataSekolah {
  final String nama;
  final String kabupaten;
  final String propinsi;
  final String tahunLulus;

  const BiodataSekolah({
    this.nama = '',
    this.kabupaten = '',
    this.propinsi = '',
    this.tahunLulus = '',
  });

  factory BiodataSekolah.fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const BiodataSekolah();
    String str(String key) => raw[key]?.toString() ?? '';
    return BiodataSekolah(
      nama: str('nama'),
      kabupaten: str('kabupaten'),
      propinsi: str('propinsi'),
      tahunLulus: str('tahun_lulus'),
    );
  }
}

class BiodataPendidikan {
  final BiodataSekolah sd;
  final BiodataSekolah smp;
  final BiodataSekolah sma;

  const BiodataPendidikan({
    required this.sd,
    required this.smp,
    required this.sma,
  });

  factory BiodataPendidikan.fromJson(Map<String, dynamic> json) =>
      BiodataPendidikan(
        sd: BiodataSekolah.fromJson(json['sd']),
        smp: BiodataSekolah.fromJson(json['smp']),
        sma: BiodataSekolah.fromJson(json['sma']),
      );
}

/// Detail satu orang tua — dipakai untuk ayah dan ibu (bentuk sama).
class BiodataOrangTuaDetail {
  final String nama;
  final String alamat;
  final String rt;
  final String rw;
  final String kecamatan;
  final String kabupaten;
  final String propinsi;
  final String kodePos;
  final String pendidikan;
  final String pekerjaan;
  final String pekerjaanLainnya;
  final String status;
  final String noHp;
  final String nipNrp;
  final String pangkat;
  final String jabatan;
  final String instansi;

  const BiodataOrangTuaDetail({
    this.nama = '',
    this.alamat = '',
    this.rt = '',
    this.rw = '',
    this.kecamatan = '',
    this.kabupaten = '',
    this.propinsi = '',
    this.kodePos = '',
    this.pendidikan = '',
    this.pekerjaan = '',
    this.pekerjaanLainnya = '',
    this.status = '',
    this.noHp = '',
    this.nipNrp = '',
    this.pangkat = '',
    this.jabatan = '',
    this.instansi = '',
  });

  factory BiodataOrangTuaDetail.fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const BiodataOrangTuaDetail();
    String str(String key) => raw[key]?.toString() ?? '';
    return BiodataOrangTuaDetail(
      nama: str('nama'),
      alamat: str('alamat'),
      rt: str('rt'),
      rw: str('rw'),
      kecamatan: str('kecamatan'),
      kabupaten: str('kabupaten'),
      propinsi: str('propinsi'),
      kodePos: str('kode_pos'),
      pendidikan: str('pendidikan'),
      pekerjaan: str('pekerjaan'),
      pekerjaanLainnya: str('pekerjaan_lainnya'),
      status: str('status'),
      noHp: str('no_hp'),
      nipNrp: str('nip_nrp'),
      pangkat: str('pangkat'),
      jabatan: str('jabatan'),
      instansi: str('instansi'),
    );
  }
}

class BiodataOrangTua {
  final BiodataOrangTuaDetail ayah;
  final BiodataOrangTuaDetail ibu;

  const BiodataOrangTua({required this.ayah, required this.ibu});

  factory BiodataOrangTua.fromJson(Map<String, dynamic> json) =>
      BiodataOrangTua(
        ayah: BiodataOrangTuaDetail.fromJson(json['ayah']),
        ibu: BiodataOrangTuaDetail.fromJson(json['ibu']),
      );
}
