import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/skmk.dart';
import 'api_client.dart';

class SkmkService {
  final Dio _dio;

  SkmkService() : _dio = ApiClient.instance.dio;

  Future<SkmkData> getSkmkData() => ApiClient.guard<SkmkData>(() async {
        final response = await _dio.get('/api/v1/skmk');
        final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
        return SkmkData.fromJson(data);
      }, 'Gagal memuat data pengajuan SKMK');

  Future<MutationResult> submitSkmk(String keperluan, String ortu) =>
      ApiClient.guard<MutationResult>(() async {
        final response = await _dio.post(
          '/api/v1/skmk',
          data: {
            'keperluan': keperluan,
            'ortu': ortu,
          },
        );
        return ApiClient.unwrapMutation(response.data);
      }, 'Gagal menambahkan pengajuan SKMK');

  Future<MutationResult> deleteSkmk(String id) =>
      ApiClient.guard<MutationResult>(() async {
        final response = await _dio.delete('/api/v1/skmk/$id');
        return ApiClient.unwrapMutation(response.data);
      }, 'Gagal menghapus pengajuan SKMK');
}
