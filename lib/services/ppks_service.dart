import 'package:dio/dio.dart';
import '../models/ppks.dart';
import 'api_client.dart';

class PpksService {
  final Dio _dio;

  PpksService() : _dio = ApiClient.instance.dio;

  Future<PpksData> getPpksData() async {
    try {
      final response = await _dio.get('/api/v1/ppks');
      final data = ApiClient.unwrapData<dynamic>(response.data);
      if (data is Map<String, dynamic>) {
        return PpksData.fromJson(data);
      } else if (data is Map) {
        return PpksData.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Gagal memuat formulir pengaduan PPKS');
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat formulir pengaduan PPKS');
    }
  }

  Future<Map<String, dynamic>> submitPpks(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(
        '/api/v1/ppks',
        data: body,
      );
      final mutation = ApiClient.unwrapMutation(response.data);
      return mutation.rawRoot ?? {'success': mutation.success, 'message': mutation.message};
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengirim pengaduan PPKS');
    }
  }
}
