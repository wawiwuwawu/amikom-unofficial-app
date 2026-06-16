import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/berita.dart';

class BeritaService {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getBerita({int offset = 0}) async {
    try {
      final response = await _dio.get('/api/v1/berita', queryParameters: {
        if (offset > 0) 'offset': offset,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat berita');
    }
  }

  Future<BeritaDetail> getBeritaById(String id) async {
    try {
      final response = await _dio.get('/api/v1/berita/$id');
      return BeritaDetail.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          throw Exception(msg);
        }
      }
      throw Exception(e.message ?? 'Gagal memuat detail berita');
    }
  }
}
