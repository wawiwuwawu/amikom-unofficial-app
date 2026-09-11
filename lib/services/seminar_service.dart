import 'package:dio/dio.dart';
import '../models/seminar.dart';
import 'api_client.dart';

class SeminarService {
  final ApiClient _client = ApiClient.instance;

  Future<List<Seminar>> getJadwalKP() async {
    try {
      final response = await _client.dio.get('/api/v1/seminar/kp');
      final list = ApiClient.unwrapData<List>(response.data);
      return list.map((e) => Seminar.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e, 'Gagal mengambil jadwal KP');
    }
  }

  Future<List<Seminar>> getJadwalSkripsi() async {
    try {
      final response = await _client.dio.get('/api/v1/seminar/skripsi');
      final list = ApiClient.unwrapData<List>(response.data);
      return list.map((e) => Seminar.fromJson(e)).toList();
    } catch (e) {
      throw _handleError(e, 'Gagal mengambil jadwal Skripsi');
    }
  }

  Exception _handleError(dynamic e, [String fallback = 'Terjadi kesalahan']) {
    if (e is DioException) {
      if (e.response?.statusCode == 404) {
        return Exception('Data jadwal tidak ditemukan.');
      }
      return ApiClient.handleError(e, fallback);
    }
    if (e is Exception) return e;
    return Exception(e?.toString() ?? fallback);
  }
}
