import 'api_client.dart';
import '../models/berita.dart';

class BeritaService {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getBerita({int offset = 0}) async {
    try {
      final response = await _dio.get('/api/v1/berita', queryParameters: {
        if (offset > 0) 'offset': offset,
      });
      return ApiClient.unwrapRoot(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat berita');
    }
  }

  Future<BeritaDetail> getBeritaById(String id) async {
    try {
      final response = await _dio.get('/api/v1/berita/$id');
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      return BeritaDetail.fromJson(data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat detail berita');
    }
  }
}
