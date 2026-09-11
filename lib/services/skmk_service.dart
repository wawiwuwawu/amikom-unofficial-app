import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/skmk.dart';
import 'api_client.dart';

class SkmkService {
  final Dio _dio;

  SkmkService() : _dio = ApiClient.instance.dio;

  Future<SkmkData> getSkmkData() async {
    try {
      final response = await _dio.get('/api/v1/skmk');
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      return SkmkData.fromJson(data);
    } catch (e) {
      throw _handleError(e, 'Gagal memuat data pengajuan SKMK');
    }
  }

  Future<MutationResult> submitSkmk(String keperluan, String ortu) async {
    try {
      final response = await _dio.post(
        '/api/v1/skmk',
        data: {
          'keperluan': keperluan,
          'ortu': ortu,
        },
      );
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw _handleError(e, 'Gagal menambahkan pengajuan SKMK');
    }
  }

  Future<MutationResult> deleteSkmk(String id) async {
    try {
      final response = await _dio.delete('/api/v1/skmk/$id');
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw _handleError(e, 'Gagal menghapus pengajuan SKMK');
    }
  }

  Exception _handleError(dynamic e, [String fallback = 'Terjadi kesalahan pada layanan SKMK']) {
    if (e is DioException) {
      return ApiClient.handleError(e, fallback);
    }
    if (e is Exception) return e;
    return Exception(e?.toString() ?? fallback);
  }
}
