import 'package:dio/dio.dart';
import '../models/surat_tugas.dart';
import 'api_client.dart';

class SuratTugasService {
  final Dio _dio;

  SuratTugasService() : _dio = ApiClient.instance.dio;

  Future<SuratTugasData> getSuratTugasData() async {
    try {
      final response = await _dio.get('/api/v1/surat-tugas');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return SuratTugasData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat data Surat Tugas');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<List<SearchMahasiswaItem>> searchMahasiswa(String term) async {
    try {
      final response = await _dio.get(
        '/api/v1/surat-tugas/search-mahasiswa',
        queryParameters: {'term': term},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => SearchMahasiswaItem.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (_) {
      return [];
    }
  }

  Future<List<SuratTugasMember>> getMembers(String idSurat) async {
    try {
      final response = await _dio.get('/api/v1/surat-tugas/$idSurat/members');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => SuratTugasMember.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<Map<String, dynamic>> submitSuratTugas(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(
        '/api/v1/surat-tugas',
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Gagal mengajukan Surat Tugas');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<Map<String, dynamic>> updateSuratTugas(String idSurat, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put(
        '/api/v1/surat-tugas/$idSurat',
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Gagal mengedit Surat Tugas');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<Map<String, dynamic>> deleteSuratTugas(String idSurat) async {
    try {
      final response = await _dio.delete('/api/v1/surat-tugas/$idSurat');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.data ?? {'success': true, 'message': 'Data surat tugas berhasil dihapus'};
      }
      throw Exception(response.data?['message'] ?? 'Gagal menghapus Surat Tugas');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }
}
