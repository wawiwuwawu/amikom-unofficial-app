import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/sp.dart';
import 'api_client.dart';

class SpService {
  final Dio _dio;

  SpService() : _dio = ApiClient.instance.dio;

  Future<SpAvailableData> getAvailable() async {
    try {
      final response = await _dio.get('/api/v1/sp/available');
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      return SpAvailableData.fromJson(data);
    } catch (e) {
      throw _handleError(e, 'Gagal memuat daftar matakuliah SP yang tersedia');
    }
  }

  Future<SpTakenData> getTaken() async {
    try {
      final response = await _dio.get('/api/v1/sp/taken');
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      return SpTakenData.fromJson(data);
    } catch (e) {
      throw _handleError(e, 'Gagal memuat matakuliah SP yang sudah diambil');
    }
  }

  Future<SpRekomendasiData> getRekomendasi() async {
    try {
      final response = await _dio.get('/api/v1/sp/rekomendasi');
      final data = ApiClient.unwrapData<Map<String, dynamic>>(response.data);
      return SpRekomendasiData.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return SpRekomendasiData(
          hasRekomendasi: false,
          warningMessage: '',
          totalRekomendasi: 0,
          totalSks: 0,
          kategoriSangatDianjurkan: [],
          kategoriOpsionalSksBesar: [],
        );
      }
      throw _handleError(e, 'Gagal memuat rekomendasi SP');
    } catch (e) {
      throw _handleError(e, 'Gagal memuat rekomendasi SP');
    }
  }

  Future<MutationResult> submitSp(List<String> kodeList) async {
    try {
      final response = await _dio.post(
        '/api/v1/sp/submit',
        data: {'kode': kodeList},
      );
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw _handleError(e, 'Gagal mengajukan matakuliah SP');
    }
  }

  Future<MutationResult> deleteSp(String idKrs) async {
    try {
      final response = await _dio.delete('/api/v1/sp/$idKrs');
      return ApiClient.unwrapMutation(response.data);
    } catch (e) {
      throw _handleError(e, 'Gagal menghapus matakuliah SP');
    }
  }

  Exception _handleError(dynamic e, [String fallback = 'Terjadi kesalahan pada layanan SP']) {
    if (e is DioException) {
      return ApiClient.handleError(e, fallback);
    }
    if (e is Exception) return e;
    return Exception(e?.toString() ?? fallback);
  }
}
