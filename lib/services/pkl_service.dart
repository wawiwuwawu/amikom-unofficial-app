import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/pkl.dart';
import 'api_client.dart';

class PklService {
  final Dio _dio;

  PklService() : _dio = ApiClient.instance.dio;

  Future<PklData> getPklData() async {
    try {
      final response = await _dio.get('/api/v1/pkl');
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      return PklData.fromJson(data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data pendaftaran PKL');
    }
  }

  Future<MutationResult> submitPkl(String jenis, String judul) async {
    try {
      final response = await _dio.post(
        '/api/v1/pkl',
        data: {
          'jenis': jenis,
          'judul': judul,
        },
      );
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menambahkan pendaftaran PKL');
    }
  }

  Future<String> downloadFormulirPkl(String idPengajuan) async {
    try {
      // ponytail: centralized download dir via ApiClient
      final dir = await ApiClient.getDownloadDir();
      final nim = ApiClient.instance.nim ?? '';
      final savePath = '$dir/Formulir_PKL_${idPengajuan}_$nim.pdf';

      await _dio.download(
        '/api/v1/pkl/download/$idPengajuan',
        savePath,
        options: Options(responseType: ResponseType.bytes),
      );

      return savePath;
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengunduh formulir PKL');
    }
  }

  Future<MutationResult> deletePkl(String idPengajuan) async {
    try {
      final response = await _dio.delete('/api/v1/pkl/$idPengajuan');
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus pendaftaran PKL');
    }
  }
}
