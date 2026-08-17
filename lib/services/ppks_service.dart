import 'package:dio/dio.dart';
import '../models/ppks.dart';
import 'api_client.dart';

class PpksService {
  final Dio _dio;

  PpksService() : _dio = ApiClient.instance.dio;

  Future<PpksData> getPpksData() async {
    try {
      final response = await _dio.get('/api/v1/ppks');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return PpksData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat formulir pengaduan PPKS');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<Map<String, dynamic>> submitPpks(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(
        '/api/v1/ppks',
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Gagal mengirim pengaduan PPKS');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }
}
