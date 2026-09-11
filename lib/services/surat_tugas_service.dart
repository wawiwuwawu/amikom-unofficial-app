import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/surat_tugas.dart';
import 'api_client.dart';

class SuratTugasService {
  final Dio _dio;

  SuratTugasService() : _dio = ApiClient.instance.dio;

  Future<SuratTugasData> getSuratTugasData() async {
    try {
      final response = await _dio.get('/api/v1/surat-tugas');
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      return SuratTugasData.fromJson(data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat data Surat Tugas');
    }
  }

  Future<List<SearchMahasiswaItem>> searchMahasiswa(String term) async {
    try {
      final response = await _dio.get(
        '/api/v1/surat-tugas/search-mahasiswa',
        queryParameters: {'term': term},
      );
      final list = ApiClient.unwrapData<List>(response.data);
      return list.map((e) => SearchMahasiswaItem.fromJson(e)).toList();
    } on DioException catch (_) {
      return [];
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mencari data mahasiswa');
    }
  }

  Future<List<SuratTugasMember>> getMembers(String idSurat) async {
    try {
      final response = await _dio.get('/api/v1/surat-tugas/$idSurat/members');
      final list = ApiClient.unwrapData<List>(response.data);
      return list.map((e) => SuratTugasMember.fromJson(e)).toList();
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal memuat anggota surat tugas');
    }
  }

  Future<MutationResult> submitSuratTugas(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(
        '/api/v1/surat-tugas',
        data: body,
      );
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengajukan Surat Tugas');
    }
  }

  Future<MutationResult> updateSuratTugas(String idSurat, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put(
        '/api/v1/surat-tugas/$idSurat',
        data: body,
      );
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal mengedit Surat Tugas');
    }
  }

  Future<MutationResult> deleteSuratTugas(String idSurat) async {
    try {
      final response = await _dio.delete('/api/v1/surat-tugas/$idSurat');
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw ApiClient.handleError(e, 'Gagal menghapus Surat Tugas');
    }
  }
}
