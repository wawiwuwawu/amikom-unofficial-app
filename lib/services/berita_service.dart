import 'api_client.dart';
import '../models/berita.dart';

class BeritaService {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getBerita({int offset = 0}) =>
      ApiClient.guard<Map<String, dynamic>>(() async {
        final response = await _dio.get('/api/v1/berita', queryParameters: {
          if (offset > 0) 'offset': offset,
        });
        return ApiClient.unwrapRoot(response.data);
      }, 'Gagal memuat berita');

  Future<BeritaDetail> getBeritaById(String id) =>
      ApiClient.guard<BeritaDetail>(() async {
        final response = await _dio.get('/api/v1/berita/$id');
        final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
        return BeritaDetail.fromJson(data);
      }, 'Gagal memuat detail berita');
}
