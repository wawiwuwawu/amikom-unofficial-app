import 'package:dio/dio.dart';
import '../models/sp.dart';
import 'api_client.dart';

class SpService {
  final Dio _dio;

  SpService() : _dio = ApiClient.instance.dio;

  Future<SpAvailableData> getAvailable() async {
    try {
      final response = await _dio.get('/api/v1/sp/available');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return SpAvailableData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat daftar matakuliah SP yang tersedia');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<SpTakenData> getTaken() async {
    try {
      final response = await _dio.get('/api/v1/sp/taken');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return SpTakenData.fromJson(response.data['data']);
      }
      throw Exception('Gagal memuat matakuliah SP yang sudah diambil');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<SpRekomendasiData> getRekomendasi() async {
    try {
      final response = await _dio.get('/api/v1/sp/rekomendasi');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return SpRekomendasiData.fromJson(response.data['data']);
      }
      return SpRekomendasiData(
        hasRekomendasi: false,
        warningMessage: '',
        totalRekomendasi: 0,
        totalSks: 0,
        kategoriSangatDianjurkan: [],
        kategoriOpsionalSksBesar: [],
      );
    } on DioException catch (_) {
      return SpRekomendasiData(
        hasRekomendasi: false,
        warningMessage: '',
        totalRekomendasi: 0,
        totalSks: 0,
        kategoriSangatDianjurkan: [],
        kategoriOpsionalSksBesar: [],
      );
    }
  }

  Future<Map<String, dynamic>> submitSp(List<String> kodeList) async {
    try {
      final response = await _dio.post(
        '/api/v1/sp/submit',
        data: {'kode': kodeList},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Gagal mengajukan matakuliah SP');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<Map<String, dynamic>> deleteSp(String idKrs) async {
    try {
      final response = await _dio.delete('/api/v1/sp/$idKrs');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.data ?? {'success': true, 'message': 'Data mata kuliah SP berhasil dihapus'};
      }
      throw Exception(response.data?['message'] ?? 'Gagal menghapus matakuliah SP');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }
}
