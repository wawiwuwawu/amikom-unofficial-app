import 'package:dio/dio.dart';
import '../models/ppks.dart';
import 'api_client.dart';
import '../models/app_failure.dart';

class PpksService {
  final Dio _dio;

  PpksService() : _dio = ApiClient.instance.dio;

  Future<PpksData> getPpksData() => ApiClient.guard<PpksData>(() async {
        final response = await _dio.get('/api/v1/ppks');
        final data = ApiClient.unwrapData<dynamic>(response.data);
        if (data is Map<String, dynamic>) {
          return PpksData.fromJson(data);
        } else if (data is Map) {
          return PpksData.fromJson(Map<String, dynamic>.from(data));
        }
        throw const AppFailure('Gagal memuat formulir pengaduan PPKS');
      }, 'Gagal memuat formulir pengaduan PPKS');

  Future<Map<String, dynamic>> submitPpks(Map<String, dynamic> body) =>
      ApiClient.guard<Map<String, dynamic>>(() async {
        final response = await _dio.post(
          '/api/v1/ppks',
          data: body,
        );
        return ApiClient.mutationRoot(response.data);
      }, 'Gagal mengirim pengaduan PPKS');
}
