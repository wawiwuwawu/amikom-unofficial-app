import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/khs.dart';

class KhsService {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getOptions() =>
      ApiClient.guard<Map<String, dynamic>>(() async {
        // Tangkap semua error (bukan hanya DioException) supaya pesan teknis
        // dari Dio/parsing tidak pernah bocor ke UI.
        final response = await _dio.get('/api/v1/khs');
        return ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      }, 'Gagal memuat data KHS. Silakan coba lagi.');

  Future<KhsDetailResponse> getDetail(String thn, String smt) =>
      ApiClient.guard<KhsDetailResponse>(() async {
        final response = await _dio.post(
          '/api/v1/khs/detail',
          data: {'thn': thn, 'smt': smt},
        );
        return KhsDetailResponse.fromJson(
          ApiClient.unwrapData<Map<String, dynamic>>(response.data),
        );
      }, 'Gagal memuat detail KHS. Silakan coba lagi.');

  Future<String> download(String thn, String smt) =>
      ApiClient.guard<String>(() async {
        // ponytail: centralized download dir via ApiClient
        final dir = await ApiClient.getDownloadDir();
        final nim = ApiClient.instance.nim ?? '';
        final nama = ApiClient.instance.nama ?? '';
        final namaFile = nama.isNotEmpty ? '$nama ($nim)' : nim;
        final safeThn = thn.replaceAll('/', '_');
        final savePath = '$dir/KHS_${namaFile}_${safeThn}_SMT$smt.pdf';
        await _dio.download(
          '/api/v1/khs/download',
          savePath,
          data: {'thn': thn, 'smt': smt},
          options: Options(method: 'POST'),
        );
        return savePath;
      }, 'Gagal mengunduh KHS. Silakan coba lagi.');
}
