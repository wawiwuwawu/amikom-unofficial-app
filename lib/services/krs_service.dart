import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/api_response.dart';
import '../models/krs.dart';

class KrsService {
  final _dio = ApiClient.instance.dio;

  Future<KrsInfo> getInfo() => ApiClient.guard<KrsInfo>(() async {
        final response = await _dio.get('/api/v1/krs');
        final root = ApiClient.unwrapRoot(response.data);
        return KrsInfo.fromJson(root);
      }, 'Gagal memuat informasi KRS');

  Future<MatkulDitawarkanResponse> getMatkulDitawarkan() =>
      ApiClient.guard<MatkulDitawarkanResponse>(() async {
        final response = await _dio.get('/api/v1/krs/matkul-ditawarkan');
        final root = ApiClient.unwrapRoot(response.data);
        return MatkulDitawarkanResponse.fromJson(root);
      }, 'Gagal memuat mata kuliah yang ditawarkan');

  Future<KrsPengajuanResponse> getPengajuan() =>
      ApiClient.guard<KrsPengajuanResponse>(() async {
        final response = await _dio.get('/api/v1/krs/pengajuan');
        final root = ApiClient.unwrapRoot(response.data);
        return KrsPengajuanResponse.fromJson(root);
      }, 'Gagal memuat pengajuan KRS');

  Future<MutationResult> submitPengajuan(List<String> makul) =>
      ApiClient.guard<MutationResult>(() async {
        final response = await _dio.post(
          '/api/v1/krs/pengajuan',
          data: {'makul': makul},
        );
        return ApiClient.unwrapMutation(response.data);
      }, 'Gagal mengajukan mata kuliah');

  Future<MutationResult> deletePengajuan(String id) =>
      ApiClient.guard<MutationResult>(() async {
        final response = await _dio.delete('/api/v1/krs/pengajuan/$id');
        return ApiClient.unwrapMutation(response.data);
      }, 'Gagal menghapus pengajuan mata kuliah');

  Future<KrsPengisianResponse> getPengisian() =>
      ApiClient.guard<KrsPengisianResponse>(() async {
        final response = await _dio.get('/api/v1/krs/pengisian');
        final root = ApiClient.unwrapRoot(response.data);
        return KrsPengisianResponse.fromJson(root);
      }, 'Gagal memuat pengisian KRS');

  Future<KrsPengisianResponse> getBelumDiisi() =>
      ApiClient.guard<KrsPengisianResponse>(() async {
        final response = await _dio.get('/api/v1/krs/pengisian/belum-diisi');
        final root = ApiClient.unwrapRoot(response.data);
        return KrsPengisianResponse.fromJson(root);
      }, 'Gagal memuat mata kuliah yang belum diisi');

  Future<MutationResult> deletePengisian(String kode) =>
      ApiClient.guard<MutationResult>(() async {
        final response = await _dio.delete('/api/v1/krs/pengisian/$kode');
        return ApiClient.unwrapMutation(response.data);
      }, 'Gagal menghapus kelas pengisian');

  Future<MutationResult> sinkronisasi() =>
      ApiClient.guard<MutationResult>(() async {
        final response = await _dio.post('/api/v1/krs/sinkronisasi', data: {});
        return ApiClient.unwrapMutation(response.data);
      }, 'Gagal melakukan sinkronisasi KRS');

  Future<String> downloadKrs(Function(int, int)? onReceiveProgress) =>
      ApiClient.guard<String>(() async {
        final response = await _dio.get(
          '/api/v1/krs/download',
          options: Options(responseType: ResponseType.bytes),
          onReceiveProgress: onReceiveProgress,
        );
        final ext = ApiClient.extensionFromHeaders(response.headers);
        // Semester aktif dari tagihan KRS (satu-satunya sumber semester di
        // payload KRS); kosong → nama tanpa semester (fail-open).
        String? semester;
        String? tahun;
        try {
          final info = await getInfo();
          final tagihan = info.tagihan;
          if (tagihan != null) {
            final sem = tagihan.semester.trim();
            if (sem.isNotEmpty) semester = 'SMT$sem';
            final thn = tagihan.tahunAkademik.trim();
            if (thn.isNotEmpty) tahun = thn.replaceAll('/', '-');
          }
        } catch (_) {
          // Info gagal → tetap unduh, nama tanpa konteks semester.
        }
        final namaFile = ApiClient.susunNamaBerkas(
          jenis: 'KRS',
          tahun: tahun,
          semester: semester,
          ext: ext,
        );
        return ApiClient.simpanKeDownload(namaFile, response.data ?? []);
      }, 'Gagal mengunduh KRS PDF');
}
