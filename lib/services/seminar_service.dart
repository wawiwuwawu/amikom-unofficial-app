import 'package:dio/dio.dart';
import '../models/seminar.dart';
import 'api_client.dart';

class SeminarService {
  final ApiClient _client = ApiClient.instance;

  Future<List<Seminar>> getJadwalKP() async {
    try {
      final response = await _client.dio.get('/api/v1/seminar/kp');
      if (response.data is List) {
        return (response.data as List).map((e) => Seminar.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Data jadwal KP tidak ditemukan.');
      }
      throw Exception(e.message ?? 'Gagal mengambil jadwal KP');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<List<Seminar>> getJadwalSkripsi() async {
    try {
      final response = await _client.dio.get('/api/v1/seminar/skripsi');
      if (response.data is List) {
        return (response.data as List).map((e) => Seminar.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Data jadwal Skripsi tidak ditemukan.');
      }
      throw Exception(e.message ?? 'Gagal mengambil jadwal Skripsi');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
