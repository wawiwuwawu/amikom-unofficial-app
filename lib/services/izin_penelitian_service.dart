import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/izin_penelitian.dart';
import 'api_client.dart';

class IzinPenelitianService {
  final Dio _dio;

  IzinPenelitianService() : _dio = ApiClient.instance.dio;

  Future<IzinPenelitianData> getIzinPenelitianData() async {
    try {
      final response = await _dio.get('/api/v1/izin-penelitian');
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      return IzinPenelitianData.fromJson(data);
    } catch (e) {
      throw _handleError(e, 'Gagal memuat data Izin Penelitian');
    }
  }

  Future<MutationResult> submitIzinPenelitian(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(
        '/api/v1/izin-penelitian',
        data: body,
      );
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw _handleError(e, 'Gagal menambahkan pengajuan izin penelitian');
    }
  }

  Future<MutationResult> deleteIzinPenelitian(String id) async {
    try {
      final response = await _dio.delete('/api/v1/izin-penelitian/$id');
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw _handleError(e, 'Gagal menghapus pengajuan izin penelitian');
    }
  }

  Exception _handleError(dynamic e, [String fallback = 'Terjadi kesalahan pada layanan Izin Penelitian']) {
    if (e is DioException) {
      return ApiClient.handleError(e, fallback);
    }
    if (e is Exception) return e;
    return Exception(e?.toString() ?? fallback);
  }
}
