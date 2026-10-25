import 'api_client.dart';
import '../models/absensi.dart';
import '../models/absensi_validasi.dart';
import '../models/app_failure.dart';
import '../models/value_label_option.dart';
import '../utils/waktu.dart';

class AbsensiService {
  final _dio = ApiClient.instance.dio;

  Future<List<MakulBelumValidasi>> getMakulBelumValidasi() =>
      ApiClient.guard<List<MakulBelumValidasi>>(() async {
        final response = await _dio.get('/api/v1/absensi/makul-belum-validasi');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        if (data is Map) {
          return data.entries
              .map((e) => MakulBelumValidasi.fromJson(
                  MapEntry<String, dynamic>(e.key.toString(), e.value)))
              .toList();
        }
        return [];
      }, 'Gagal memuat data absensi');

  Future<List<ValueLabelOption>> getSemester(String thnAkademik) =>
      ApiClient.guard<List<ValueLabelOption>>(() async {
        final response = await _dio.post(
          '/api/v1/absensi/semester',
          data: {'thn_akademik': thnAkademik},
        );
        final data = ApiClient.unwrapData<List>(response.data);
        return ApiClient.unwrapList<ValueLabelOption>(
            data, ValueLabelOption.fromJson);
      }, 'Gagal memuat semester');

  Future<List<ValueLabelOption>> getMatkul(String thnAkademik, String semester) =>
      ApiClient.guard<List<ValueLabelOption>>(() async {
        final response = await _dio.post(
          '/api/v1/absensi/matkul',
          data: {'thn_akademik': thnAkademik, 'semester': semester},
        );
        final data = ApiClient.unwrapData<List>(response.data);
        return ApiClient.unwrapList<ValueLabelOption>(
            data, ValueLabelOption.fromJson);
      }, 'Gagal memuat matakuliah');

  Future<AbsensiMahasiswa> getMahasiswa(
          String thnAkademik, String semester, String makul) =>
      ApiClient.guard<AbsensiMahasiswa>(() async {
        final response = await _dio.post(
          '/api/v1/absensi/mahasiswa',
          data: {
            'thn_akademik': thnAkademik,
            'semester': semester,
            'makul': makul,
          },
        );
        return AbsensiMahasiswa.fromJson(
            ApiClient.unwrapData<Map<String, dynamic>>(response.data));
      }, 'Gagal memuat data mahasiswa');

  Future<PresensiDetail> getPresensiDetail(String id) =>
      ApiClient.guard<PresensiDetail>(() async {
        final response = await _dio.get('/api/v1/absensi/presensi/$id');
        return PresensiDetail.fromJson(
            ApiClient.unwrapData<Map<String, dynamic>>(response.data));
      }, 'Gagal memuat detail presensi');

  Future<void> validasi(Map<String, dynamic> data) =>
      ApiClient.guard<void>(() async {
        final response = await _dio.post('/api/v1/absensi/validasi', data: data);
        ApiClient.unwrapMutation(response.data);
        final dynamic raw = response.data;
        if (raw is Map<String, dynamic>) {
          final innerData = raw['data'];
          if (innerData is Map<String, dynamic>) {
            final nested = innerData['data'];
            if (nested is Map<String, dynamic> && nested['success'] == false) {
              throw AppFailure.fromServer(
                  nested['message'], fallback: 'Validasi presensi ditolak');
            }
            if (innerData['success'] == false) {
              throw AppFailure.fromServer(
                  innerData['message'], fallback: 'Validasi presensi ditolak');
            }
          }
        }
      }, 'Gagal melakukan validasi');

  /// Auto-validasi massal portal: `inspeksi` hanya memeriksa, `tulis` benar-
  /// benar menulis. Endpoint ini menjawab HTTP 200 dengan envelope galat
  /// ({status:'error'} atau `data.success:false`), jadi root WAJIB dipecah
  /// manual — `unwrapData` hanya akan menelan penolakan sebagai hasil nol.
  Future<AutoValidasiResult> autoValidasi(
    AutoValidasiMode mode, {
    String preset = 'wajar',
  }) =>
      ApiClient.guard<AutoValidasiResult>(() async {
        final response = await _dio.post(
          '/api/v1/absensi/auto-validasi',
          data: {'mode': mode.wire, 'preset': preset},
        );
        final root = ApiClient.unwrapRoot(response.data);
        final data = root['data'];
        if (root['status'] != 'success' || data is! Map<String, dynamic>) {
          throw AppFailure.fromServer(
            root['message'],
            fallback: 'Gagal memproses validasi otomatis',
          );
        }
        if (data['success'] == false) {
          throw AppFailure.fromServer(
            data['message'],
            fallback: 'Validasi otomatis ditolak portal',
          );
        }
        return AutoValidasiResult.fromJson(data);
      }, 'Gagal memproses validasi otomatis');

  // ── Deteksi "sudah presensi hari ini" untuk kartu berjalan di beranda ─────

  /// Best-effort: menjawab "apakah pengguna sudah presensi untuk [makul]
  /// (NAMA tampilan dari agenda, mis. 'Pemrograman Mobile') hari ini?".
  ///
  /// Keterbatasan (dokumentasi fail-open — JANGAN anggap ini ground truth):
  /// 1. Endpoint riwayat butuh `thn_akademik` + `semester` + `makul`, sedangkan
  ///    agenda beranda hanya membawa nama matakuliah. Rantai yang dipakai:
  ///    `semester` (pilih periode aktif dari daftar) → `matkul` (cocokkan nama
  ///    secara longgar) → `mahasiswa` (riwayat pertemuan). Salah satu tahap
  ///    gagal/kosong → dianggap belum presensi.
  /// 2. `semester` dipilih dari daftar respons BE dengan heuristik ganjil/
  ///    genap; bila ambigu (tidak ada/tidak jelas kandidatnya) → false.
  /// 3. `tanggal` riwayat portal berformat panjang Indonesia ("Senin, 7
  ///    September 2026") — diparse longgar; gagal parse → tidak dihitung.
  ///
  /// Aturan fail-open KERAS: galat apa pun (jaringan, sesi, parsing) hanya
  /// mengembalikan `false` — TIDAK pernah melempar; pemanggil boleh (tapi tak
  /// wajib) menangkap ulang. UI yang tampil saat `false` adalah tombol
  /// "Presensi Sekarang", artinya fail-open berujung pada perilaku lama.
  Future<bool> sudahPresensiHariIni({required String makul}) async {
    try {
      final now = DateTime.now();
      final (thn, ganjil) = _periodeAkademikAktif(now);

      final semesterList = await getSemester(thn);
      final smt = _pilihSemesterAktif(semesterList, ganjil);
      if (smt == null) return false;

      final matkulList = await getMatkul(thn, smt);
      final kode = _cariMakul(matkulList, makul);
      if (kode == null) return false;

      final mhs = await getMahasiswa(thn, smt, kode);
      return mhs.riwayatPertemuan.any(
        (r) =>
            _tanggalPortalSamaHariIni(r.tanggal, now) && _sudahTercatat(r),
      );
    } catch (_) {
      // Fail-open: cek ini hanya mempercantik UX, kegagalannya tidak boleh
      // menyentuh UI (kartu kembali berperilaku seperti sebelum fase ini).
      return false;
    }
  }

  /// Periode akademik aktif: (tahun "yyyy/yyyy", apakah semester ganjil).
  /// Aturan sama dengan filter di AbsensiPage: Agustus–Desember membuka
  /// tahun ajaran baru (ganjil), Januari melanjutkan ganjil, Feb–Juli genap.
  static (String, bool) _periodeAkademikAktif(DateTime now) {
    final y = now.year;
    if (now.month >= 8) return ('$y/${y + 1}', true);
    if (now.month == 1) return ('${y - 1}/$y', true);
    return ('${y - 1}/$y', false);
  }

  /// Pilih satu opsi semester aktif dari daftar BE. Kandidat dicocokkan
  /// lewat angka 1/2 berdiri sendiri atau kata gasal/ganjil/genap — BE tidak
  /// punya kontrak eksplisit di sisi klien, jadi ambigu → null (fail-open).
  static String? _pilihSemesterAktif(
    List<ValueLabelOption> options,
    bool ganjil,
  ) {
    final kataKunci = ganjil ? <String>['gasal', 'ganjil'] : <String>['genap'];
    final angka = RegExp(ganjil ? r'(^|\D)1($|\D)' : r'(^|\D)2($|\D)');
    final kandidat = options
        .where(
          (o) =>
              kataKunci.any(
                (k) =>
                    o.value.toLowerCase().contains(k) ||
                    o.label.toLowerCase().contains(k),
              ) ||
              angka.hasMatch(o.value) ||
              angka.hasMatch(o.label),
        )
        .map((o) => o.value)
        .toSet();
    return kandidat.length == 1 ? kandidat.first : null;
  }

  /// Cocokkan nama matakuliah agenda ke opsi `matkul` secara longgar:
  /// normalisasi non-alfanumerik lalu "mengandung" dua arah (nama agenda bisa
  /// lebih pendek/panjang dari label portal). Ambigu → opsi pertama (fail-
  /// open tetap memakai satu kandidat terbaik); tak ada kandidat → null.
  static String? _cariMakul(List<ValueLabelOption> options, String nama) {
    final cari = _normalisasiMakul(nama);
    if (cari.isEmpty) return null;
    for (final o in options) {
      final label = _normalisasiMakul(o.label);
      final value = _normalisasiMakul(o.value);
      if ((label.isNotEmpty && (label.contains(cari) || cari.contains(label))) ||
          (value.isNotEmpty &&
              (value.contains(cari) || cari.contains(value)))) {
        return o.value;
      }
    }
    return null;
  }

  static String _normalisasiMakul(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Presensi terhitung tercatat bila status kehadiran H/I/S, ATAU baris
  /// memakai `id_presensi` (tautan detail). Slot status 'B' tanpa id adalah
  /// pertemuan yang belum diisi — bukan presensi.
  static bool _sudahTercatat(RiwayatPertemuan r) {
    switch (r.status.toUpperCase()) {
      case 'H':
      case 'I':
      case 'S':
        return true;
    }
    final id = r.idPresensi;
    return id != null && id.isNotEmpty;
  }

  /// Samakan `tanggal` riwayat portal (mis. "Senin, 7 September 2026", juga
  /// menerima "yyyy-MM-dd"/"dd-MM-yyyy" via [tanggalDariPortal]) dengan hari
  /// ini. Gagal parse → false (bukan tanggal hari ini).
  static bool _tanggalPortalSamaHariIni(String tanggal, DateTime now) {
    final portal = tanggalDariPortal(tanggal) ?? _parseTanggalIndoPanjang(tanggal);
    if (portal == null) return false;
    return portal.year == now.year &&
        portal.month == now.month &&
        portal.day == now.day;
  }

  /// Parse format portal "Hari, d Bulan yyyy" (mis. "Senin, 7 September 2026";
  /// "Sept" juga diterima). Null bila bentuknya bukan format ini.
  static DateTime? _parseTanggalIndoPanjang(String teks) {
    final bersih = teks.contains(',') ? teks.split(',').last.trim() : teks.trim();
    final bagian = bersih
        .split(RegExp(r'\s+'))
        .where((b) => b.isNotEmpty)
        .toList();
    if (bagian.length != 3) return null;
    final d = int.tryParse(bagian[0]);
    final y = int.tryParse(bagian[2]);
    final m = _bulanIndoKeAngka(bagian[1]);
    if (d == null || y == null || m == null) return null;
    final t = DateTime(y, m, d);
    if (t.year != y || t.month != m || t.day != d) return null;
    return t;
  }

  static int? _bulanIndoKeAngka(String nama) {
    const bulan = [
      'januari', 'februari', 'maret', 'april', 'mei', 'juni', 'juli',
      'agustus', 'september', 'oktober', 'november', 'desember',
    ];
    final k = nama.toLowerCase();
    if (k.startsWith('sept')) return 9;
    for (var i = 0; i < bulan.length; i++) {
      if (k == bulan[i] || k.startsWith(bulan[i])) return i + 1;
    }
    return null;
  }
}
