import 'dart:io' show Platform;

import 'package:dio/dio.dart';

import '../models/app_failure.dart';
import '../models/skkm.dart';
import 'api_client.dart';

/// Service SKKM (Satuan Kredit Kegiatan Mahasiswa, angkatan 2024+).
///
/// Kontrak BE 2026-11-01 §4–§5. Semua endpoint tulis menolak angkatan < 2024
/// dengan HTTP 400 + pesan kebijakan — biarkan [ApiClient.guard] memetakannya
/// ke pesan ramah, FE tidak perlu gerbang terpisah untuk kasus itu.
///
/// Catatan BE (§6.2): bentuk respons rantai dropdown dibangun dari perilaku
/// JS portal (belum tangkapan asli). Parser di sini sengaja longgar (string
/// apa adanya) supaya koreksi kecil cukup di satu titik bila produksi beda.
class SkkmService {
  final Dio _dio = ApiClient.instance.dio;

  /// Indikator lokal angkatan dari 2 digit pertama NIM — aturan yang SAMA
  /// dengan BE (panduan §4.1: "angkatan dibaca dari 2 digit pertama NIM").
  /// Dipakai FE hanya untuk UX (sembunyikan menu, lewati panggilan yang pasti
  /// ditolak); BE tetap gerbang resmi.
  ///
  /// Hasil `null` = NIM tidak tersedia / tidak bisa diparse — JANGAN dipakai
  /// memutuskan apa pun (fail-open): biarkan endpoint yang menjawab.
  static bool? berlakuDariNim(String? nim) {
    if (nim == null || nim.length < 2) return null;
    final duaDigit = int.tryParse(nim.substring(0, 2));
    if (duaDigit == null) return null;
    return 2000 + duaDigit >= 2024;
  }

  /// Daftar aktivitas + poin valid + opsi unsur langkah 1.
  Future<SkkmData> getSkkm() => ApiClient.guard<SkkmData>(() async {
        final response = await _dio.get('/api/v1/skkm');
        final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
        return SkkmData.fromJson(data);
      }, 'Gagal memuat SKKM');

  /// Langkah 2 rantai dropdown: sub-unsur dari unsur terpilih.
  Future<List<SkkmOpsi>> subUnsur(String unsur) =>
      ApiClient.guard<List<SkkmOpsi>>(() async {
        final response =
            await _dio.post('/api/v1/skkm/sub-unsur', data: {'unsur': unsur});
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return SkkmOpsi.daftarDari(data);
      }, 'Gagal memuat sub-unsur kegiatan');

  /// Langkah 3: jenis/tingkat (level) dari unsur + sub-unsur.
  Future<List<SkkmOpsi>> jenis(String unsur, String subUnsur) =>
      ApiClient.guard<List<SkkmOpsi>>(() async {
        final response = await _dio.post('/api/v1/skkm/jenis',
            data: {'unsur': unsur, 'sub_unsur': subUnsur});
        final data = ApiClient.unwrapData<dynamic>(response.data);
        return SkkmOpsi.daftarDari(data);
      }, 'Gagal memuat tingkat kegiatan');

  /// Langkah 4: poin readonly + `id_skkm` yang wajib dikirim balik saat ajukan.
  Future<SkkmKredit> kredit(String unsur, String subUnsur, String jenis) =>
      ApiClient.guard<SkkmKredit>(() async {
        final response = await _dio.post('/api/v1/skkm/kredit', data: {
          'unsur': unsur,
          'sub_unsur': subUnsur,
          'jenis': jenis,
        });
        final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
        final kredit = SkkmKredit.fromJson(data);
        if (kredit.idSkkm.isEmpty) {
          throw const AppFailure('Data poin kegiatan tidak lengkap');
        }
        return kredit;
      }, 'Gagal memuat poin kegiatan');

  /// Deskriptor input bukti yang portal minta untuk `id_skkm` ini
  /// (file ATAU teks URL — keduanya bernama `bukti_fisik` di portal).
  Future<List<SkkmBuktiInput>> inputBukti(String idSkkm) =>
      ApiClient.guard<List<SkkmBuktiInput>>(() async {
        final response = await _dio.post('/api/v1/skkm/bukti',
            data: {'id_skkm': idSkkm});
        final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
        return (data['input'] as List?)
                ?.map((e) => SkkmBuktiInput.fromJson(
                      e is Map<String, dynamic>
                          ? e
                          : Map<String, dynamic>.from(e as Map),
                    ))
                .toList() ??
            const [];
      }, 'Gagal memuat bentuk unggahan bukti');

  /// Portal men-enable tombol Ajukan hanya bila nomor surat tugas dikenal.
  Future<bool> cekSuratTugas(String suratTgs) =>
      ApiClient.guard<bool>(() async {
        final response = await _dio.post('/api/v1/skkm/cek-surat-tugas',
            data: {'surat_tgs': suratTgs});
        final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
        final exists = data['exists'];
        return exists == true || exists?.toString() == 'true';
      }, 'Gagal memeriksa surat tugas');

  /// Ajukan kegiatan (multipart/form-data, nama field persis form portal).
  /// Bukti: [buktiFile] (path PDF lokal ≤3MB) ATAU [buktiUrl] (URL publikasi).
  Future<void> tambahAktivitas({
    required String unsur,
    required String subUnsur,
    required String jenis,
    required String idSkkm,
    required String thnKeg,
    required String jenisKeg,
    required String roleKeg,
    String? kredit,
    String? jmlAnggota,
    String? suratTgs,
    String? buktiFile,
    String? buktiUrl,
  }) =>
      ApiClient.guard<void>(() async {
        if ((buktiFile == null || buktiFile.isEmpty) &&
            (buktiUrl == null || buktiUrl.isEmpty)) {
          throw const AppFailure('Bukti kegiatan wajib diunggah');
        }
        final fields = <String, dynamic>{
          'unsur': unsur,
          'sub_unsur': subUnsur,
          'jenis': jenis,
          'id_skkm': idSkkm,
          'thn_keg': thnKeg,
          'jenis_keg': jenisKeg,
          'role_keg': roleKeg,
        };
        if (kredit != null && kredit.isNotEmpty) fields['kredit'] = kredit;
        if (jmlAnggota != null && jmlAnggota.isNotEmpty) {
          fields['jml_anggota'] = jmlAnggota;
        }
        if (suratTgs != null && suratTgs.isNotEmpty) {
          fields['surat_tgs'] = suratTgs;
        }
        if (buktiFile != null && buktiFile.isNotEmpty) {
          final nama = buktiFile.split(Platform.pathSeparator).last;
          fields['bukti_fisik'] = await MultipartFile.fromFile(
            buktiFile,
            filename: nama,
          );
        } else {
          fields['bukti_fisik'] = buktiUrl;
        }
        final response = await _dio.post(
          '/api/v1/skkm/aktivitas',
          data: FormData.fromMap(fields),
        );
        // Portal menolak → 502 dengan pesan apa adanya; unwrapMutation
        // melempar AppFailure berisi pesan itu (jangan dianggap sukses).
        ApiClient.unwrapMutation(response.data);
      }, 'Gagal mengajukan kegiatan SKKM');

  /// Hapus aktivitas berstatus "Tidak Valid" (id dari `id_aktivitas`).
  Future<void> hapusAktivitas(String idAktivitas) =>
      ApiClient.guard<void>(() async {
        final response = await _dio.delete('/api/v1/skkm/aktivitas/$idAktivitas');
        ApiClient.unwrapMutation(response.data);
      }, 'Gagal menghapus aktivitas SKKM');

  /// Kritik & saran untuk validator kemahasiswaan.
  Future<void> kirimKritikSaran(String isi) =>
      ApiClient.guard<void>(() async {
        final response = await _dio.post(
          '/api/v1/skkm/kritik-saran',
          data: {'isi': isi},
        );
        ApiClient.unwrapMutation(response.data);
      }, 'Gagal mengirim kritik & saran');

  /// Unduh bukti (PDF biner) lewat proxy BE — satu-satunya jalur menampilkan
  /// bukti karena URL asli portal butuh sesi login.
  Future<String> unduhBukti(String idBukti, String namaFile) =>
      ApiClient.guard<String>(() async {
        final dir = await ApiClient.getDownloadDir();
        final savePath = '$dir/$namaFile';
        await _dio.download('/api/v1/skkm/bukti/$idBukti', savePath);
        return savePath;
      }, 'Gagal mengunduh berkas bukti');
}
