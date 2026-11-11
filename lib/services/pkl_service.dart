import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/pkl.dart';
import 'api_client.dart';

class PklService {
  final Dio _dio;

  PklService() : _dio = ApiClient.instance.dio;

  Future<PklData> getPklData() => ApiClient.guard<PklData>(() async {
        final response = await _dio.get('/api/v1/pkl');
        final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
        return PklData.fromJson(data);
      }, 'Gagal memuat data pendaftaran PKL');

  Future<MutationResult> submitPkl(String jenis, String judul) =>
      ApiClient.guard<MutationResult>(() async {
        final response = await _dio.post(
          '/api/v1/pkl',
          data: {
            'jenis': jenis,
            'judul': judul,
          },
        );
        return ApiClient.unwrapMutation(response.data);
      }, 'Gagal menambahkan pendaftaran PKL');

  Future<String> downloadFormulirPkl(String idPengajuan) =>
      ApiClient.guard<String>(() async {
        final namaFile =
            ApiClient.susunNamaBerkas(jenis: 'Formulir_PKL_$idPengajuan');

        final response = await _dio.get(
          '/api/v1/pkl/download/$idPengajuan',
          options: Options(responseType: ResponseType.bytes),
        );

        return ApiClient.simpanKeDownload(
          namaFile,
          response.data is List ? response.data as List<int> : <int>[],
        );
      }, 'Gagal mengunduh formulir PKL');

  Future<MutationResult> deletePkl(String idPengajuan) =>
      ApiClient.guard<MutationResult>(() async {
        final response = await _dio.delete('/api/v1/pkl/$idPengajuan');
        return ApiClient.unwrapMutation(response.data);
      }, 'Gagal menghapus pendaftaran PKL');
}
